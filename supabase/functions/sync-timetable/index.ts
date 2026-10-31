// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};

const EDUPAGE_URL = 'https://mru.edupage.org/timetable/server/regulartt.js?__func=regularttGetData';

const DEFAULT_PERIOD_TIMES: Record<string, { start: string; end: string; name: string }> = {
  '1': { start: '08:10', end: '09:00', name: 'Period 1' },
  '2': { start: '09:00', end: '09:50', name: 'Period 2' },
  '3': { start: '09:50', end: '10:40', name: 'Period 3' },
  '4': { start: '10:40', end: '11:30', name: 'Period 4' },
  '5': { start: '11:30', end: '12:20', name: 'Lunch Break' },
  '6': { start: '12:20', end: '13:10', name: 'Period 6' },
  '7': { start: '13:10', end: '14:00', name: 'Period 7' },
  '8': { start: '14:00', end: '14:50', name: 'Period 8' },
  '9': { start: '14:50', end: '15:40', name: 'Period 9' },
  '10': { start: '15:40', end: '16:30', name: 'Period 10' },
};

const DAYS_ORDER = [
  { key: 'Monday', short: 'Mo', bitIndex: 0 },
  { key: 'Tuesday', short: 'Tu', bitIndex: 1 },
  { key: 'Wednesday', short: 'We', bitIndex: 2 },
  { key: 'Thursday', short: 'Th', bitIndex: 3 },
  { key: 'Friday', short: 'Fr', bitIndex: 4 },
];

function normalizeSectionKey(val: string): string {
  if (!val) return '';
  return val.trim().toLowerCase().replace(/[\s\-_]+/g, '');
}

interface EdupageTables {
  classes: Map<string, { id: string; name: string; short: string }>;
  subjects: Map<string, { id: string; name: string; short: string }>;
  teachers: Map<string, { id: string; name: string; short: string }>;
  classrooms: Map<string, { id: string; name: string; short: string }>;
  groups: Map<string, { id: string; name: string; classid?: string }>;
  periods: Map<string, { id: string; period: string; name: string; starttime: string; endtime: string }>;
  lessons: Map<string, any>;
  cards: any[];
}

async function fetchEdupageData(): Promise<EdupageTables> {
  const resp = await fetch(EDUPAGE_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify({
      __args: [null, '18'],
      __gsh: '00000000',
    }),
  });

  if (!resp.ok) {
    throw new Error(`Edupage server returned status HTTP ${resp.status}`);
  }

  const raw = await resp.json();
  const rawTables = raw?.r?.dbiAccessorRes?.tables || [];

  const tableMap: Record<string, any[]> = {};
  for (const t of rawTables) {
    tableMap[t.id] = t.data_rows || [];
  }

  const classes = new Map<string, any>();
  for (const c of tableMap['classes'] || []) {
    classes.set(c.id, { id: c.id, name: (c.name || '').trim(), short: (c.short || '').trim() });
  }

  const subjects = new Map<string, any>();
  for (const s of tableMap['subjects'] || []) {
    subjects.set(s.id, { id: s.id, name: (s.name || '').trim(), short: (s.short || '').trim() });
  }

  const teachers = new Map<string, any>();
  for (const tc of tableMap['teachers'] || []) {
    teachers.set(tc.id, { id: tc.id, name: (tc.name || '').trim(), short: (tc.short || '').trim() });
  }

  const classrooms = new Map<string, any>();
  for (const cr of tableMap['classrooms'] || []) {
    classrooms.set(cr.id, { id: cr.id, name: (cr.name || '').trim(), short: (cr.short || '').trim() });
  }

  const groups = new Map<string, any>();
  for (const g of tableMap['groups'] || []) {
    groups.set(g.id, { id: g.id, name: (g.name || '').trim(), classid: g.classid });
  }

  const periods = new Map<string, any>();
  for (const p of tableMap['periods'] || []) {
    periods.set(String(p.period || p.id), {
      id: p.id,
      period: String(p.period || p.id),
      name: p.name || `Period ${p.period}`,
      starttime: p.starttime || '',
      endtime: p.endtime || '',
    });
  }

  const lessons = new Map<string, any>();
  for (const l of tableMap['lessons'] || []) {
    lessons.set(l.id, l);
  }

  const cards = tableMap['cards'] || [];

  return { classes, subjects, teachers, classrooms, groups, periods, lessons, cards };
}

function buildSectionSchedule(classId: string, className: string, tables: EdupageTables) {
  const { subjects, teachers, classrooms, groups, periods, lessons, cards } = tables;

  // Initialize day structure
  const scheduleByDay: Record<string, Record<string, any[]>> = {};
  for (const day of DAYS_ORDER) {
    scheduleByDay[day.key] = {};
    for (let p = 1; p <= 10; p++) {
      scheduleByDay[day.key][String(p)] = [];
    }
  }

  let totalSlotCount = 0;
  const uniqueSubjects = new Set<string>();
  const uniqueTeachers = new Set<string>();
  const uniqueRooms = new Set<string>();

  for (const card of cards) {
    const lesson = lessons.get(card.lessonid);
    if (!lesson) continue;

    const classids: string[] = lesson.classids || [];
    if (!classids.includes(classId)) continue;

    const dayBitmask = String(card.days || '');
    const periodStr = String(parseInt(card.period, 10));
    if (!periodStr || isNaN(Number(periodStr))) continue;

    const subjectObj = subjects.get(lesson.subjectid);
    const subjectName = subjectObj ? subjectObj.name : (lesson.subjectid || 'Unknown Subject');
    if (subjectName) uniqueSubjects.add(subjectName);

    const teacherNames: string[] = (lesson.teacherids || [])
      .map((tid: string) => teachers.get(tid)?.name)
      .filter((n?: string) => !!n);
    teacherNames.forEach((t) => uniqueTeachers.add(t));
    const facultyStr = teacherNames.length > 0 ? teacherNames.join(', ') : 'TBD';

    const roomNames: string[] = (card.classroomids || [])
      .map((cid: string) => classrooms.get(cid)?.name)
      .filter((n?: string) => !!n);
    roomNames.forEach((r) => uniqueRooms.add(r));
    const roomStr = roomNames.length > 0 ? roomNames.join(', ') : '-';

    // Group handling (G1, G2, etc.)
    const rawGroupNames: string[] = (lesson.groupids || [])
      .map((gid: string) => groups.get(gid)?.name)
      .filter((n?: string) => !!n && n.trim() !== '');

    const dedupedGroups = Array.from(new Set(rawGroupNames));
    const groupStr = dedupedGroups.length > 0 ? dedupedGroups.join(', ') : 'Entire class';

    const durationPeriods = parseInt(lesson.durationperiods || 1, 10) || 1;
    const durationMinutes = durationPeriods * 50;

    // Period timings
    const periodMeta = periods.get(periodStr) || DEFAULT_PERIOD_TIMES[periodStr];
    const startTime = periodMeta?.starttime || periodMeta?.start || '';
    const endTime = periodMeta?.endtime || periodMeta?.end || '';
    const timeLabel = startTime && endTime ? `${startTime} - ${endTime}` : '';

    const slotRecord = {
      subject: subjectName,
      faculty: facultyStr,
      teachers: teacherNames,
      room: roomStr,
      rooms: roomNames,
      group: groupStr,
      groups: dedupedGroups,
      durationPeriods: durationPeriods,
      durationMinutes: durationMinutes,
      startTime: startTime,
      endTime: endTime,
      time: timeLabel,
      isDoublePeriod: durationPeriods >= 2,
      lessonId: lesson.id,
      cardId: card.id,
    };

    // Distribute across days matching the bitmask
    for (const day of DAYS_ORDER) {
      if (dayBitmask.length > day.bitIndex && dayBitmask[day.bitIndex] === '1') {
        scheduleByDay[day.key][periodStr].push(slotRecord);
        totalSlotCount++;
      }
    }
  }

  // Count occupied periods
  let occupiedPeriodsCount = 0;
  for (const day of DAYS_ORDER) {
    for (let p = 1; p <= 10; p++) {
      if (scheduleByDay[day.key][String(p)].length > 0) {
        occupiedPeriodsCount++;
      }
    }
  }

  return {
    section: className,
    classId: classId,
    slotCount: totalSlotCount,
    occupiedPeriods: occupiedPeriodsCount,
    metadata: {
      totalSubjects: uniqueSubjects.size,
      subjects: Array.from(uniqueSubjects),
      totalFaculty: uniqueTeachers.size,
      faculty: Array.from(uniqueTeachers),
      totalRooms: uniqueRooms.size,
      rooms: Array.from(uniqueRooms),
      periodTimes: DEFAULT_PERIOD_TIMES,
    },
    days: scheduleByDay,
    // Short key alias for convenient client access
    schedule: {
      Mo: scheduleByDay['Monday'],
      Tu: scheduleByDay['Tuesday'],
      We: scheduleByDay['Wednesday'],
      Th: scheduleByDay['Thursday'],
      Fr: scheduleByDay['Friday'],
    },
  };
}

serve(async (req: Request) => {
  // 1. Handle CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 2. Initialize Supabase Client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_ANON_KEY') || '';

    let supabase: any = null;
    if (supabaseUrl && supabaseKey) {
      supabase = createClient(supabaseUrl, supabaseKey);
    }

    // 3. Parse Parameters
    let requestedSection = 'CSE 5A';
    let syncedBy = 'edge-function';
    let syncAll = false;

    if (req.method === 'POST') {
      try {
        const body = await req.json();
        if (body.section) requestedSection = body.section;
        if (body.syncedBy) syncedBy = body.syncedBy;
        if (body.syncAll === true || body.section?.toLowerCase() === 'all') syncAll = true;
      } catch (_) {
        // Fallback to query params or defaults if JSON parsing fails
      }
    } else if (req.method === 'GET') {
      const url = new URL(req.url);
      const sParam = url.searchParams.get('section');
      if (sParam) requestedSection = sParam;
      if (url.searchParams.get('syncAll') === 'true' || sParam?.toLowerCase() === 'all') {
        syncAll = true;
      }
      const uParam = url.searchParams.get('syncedBy');
      if (uParam) syncedBy = uParam;
    }

    // 4. Fetch live Edupage stream
    const edupageTables = await fetchEdupageData();

    if (syncAll) {
      // Sync all classes found in Edupage
      const results: any[] = [];
      const nowIso = new Date().toISOString();

      for (const [cid, cObj] of edupageTables.classes.entries()) {
        const schedObj = buildSectionSchedule(cid, cObj.name, edupageTables);
        if (schedObj.slotCount > 0) {
          if (supabase) {
            await supabase.from('timetable_cache').upsert(
              {
                section: cObj.name,
                schedule_data: schedObj,
                slot_count: schedObj.slotCount,
                last_synced_at: nowIso,
                synced_by: syncedBy,
              },
              { onConflict: 'section' }
            );
          }
          results.push({ section: cObj.name, slotCount: schedObj.slotCount, occupiedPeriods: schedObj.occupiedPeriods });
        }
      }

      return new Response(
        JSON.stringify({
          success: true,
          mode: 'sync_all',
          syncedCount: results.length,
          syncedAt: nowIso,
          sections: results,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
      );
    }

    // 5. Match Requested Section
    const normTarget = normalizeSectionKey(requestedSection);
    let matchedClass: { id: string; name: string; short: string } | null = null;

    for (const [_, cObj] of edupageTables.classes.entries()) {
      const normName = normalizeSectionKey(cObj.name);
      const normShort = normalizeSectionKey(cObj.short);
      if (normName === normTarget || normShort === normTarget) {
        matchedClass = cObj;
        break;
      }
    }

    // Fallback: substring matching if exact match not found
    if (!matchedClass) {
      for (const [_, cObj] of edupageTables.classes.entries()) {
        const normName = normalizeSectionKey(cObj.name);
        if (normName.includes(normTarget) || normTarget.includes(normName)) {
          matchedClass = cObj;
          break;
        }
      }
    }

    if (!matchedClass) {
      const availableSections = Array.from(edupageTables.classes.values()).map((c) => c.name);
      return new Response(
        JSON.stringify({
          success: false,
          error: `Section '${requestedSection}' not found in live Edupage timetable stream.`,
          availableSections: availableSections.slice(0, 30),
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 404 }
      );
    }

    // 6. Build the Resolved Schedule
    const schedulePayload = buildSectionSchedule(matchedClass.id, matchedClass.name, edupageTables);
    const nowIso = new Date().toISOString();

    // 7. Upsert into Supabase `timetable_cache`
    let dbStatus = 'skipped_no_client';
    if (supabase) {
      const { error: upsertError } = await supabase.from('timetable_cache').upsert(
        {
          section: matchedClass.name,
          schedule_data: schedulePayload,
          slot_count: schedulePayload.slotCount,
          last_synced_at: nowIso,
          synced_by: syncedBy,
        },
        { onConflict: 'section' }
      );

      if (upsertError) {
        console.error('Database upsert warning:', upsertError);
        dbStatus = `db_error: ${upsertError.message}`;
      } else {
        dbStatus = 'synced';
      }
    }

    // 8. Return Clean Verified Response
    return new Response(
      JSON.stringify({
        success: true,
        section: matchedClass.name,
        slotCount: schedulePayload.slotCount,
        occupiedPeriods: schedulePayload.occupiedPeriods,
        dbStatus: dbStatus,
        syncedAt: nowIso,
        schedule: schedulePayload.schedule,
        days: schedulePayload.days,
        metadata: schedulePayload.metadata,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    );
  } catch (err: any) {
    console.error('sync-timetable error:', err);
    return new Response(
      JSON.stringify({
        success: false,
        error: err.message || 'Internal server error processing timetable sync.',
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 }
    );
  }
});
