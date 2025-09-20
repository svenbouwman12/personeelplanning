// Supabase Client Setup
// Voeg dit toe aan je HTML bestanden om Supabase te gebruiken

// Supabase configuratie
const SUPABASE_URL = 'https://rxlldqiwhytwqekuvkpc.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ4bGxkcWl3aHl0d3Fla3V2a3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzOTI4NTIsImV4cCI6MjA3Mzk2ODg1Mn0.hITD_LZzG4sIkljH-Tra1WbUin1JWCBdelTTk-IyJ0Q';

// Supabase client initialiseren (je moet eerst de Supabase JS library toevoegen)
// <script src="https://unpkg.com/@supabase/supabase-js@2"></script>

const supabase = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Database functies voor Supabase

// Gebruikers functies
async function getUsers() {
    const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('is_active', true);
    
    if (error) {
        console.error('Error fetching users:', error);
        return [];
    }
    return data;
}

async function getUserByUsername(username) {
    const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('username', username)
        .single();
    
    if (error) {
        console.error('Error fetching user:', error);
        return null;
    }
    return data;
}

async function createUser(userData) {
    const { data, error } = await supabase
        .from('users')
        .insert([userData])
        .select()
        .single();
    
    if (error) {
        console.error('Error creating user:', error);
        return null;
    }
    return data;
}

// Rooster functies
async function getShiftsForWeek(weekStart) {
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekEnd.getDate() + 6);
    
    const { data, error } = await supabase
        .from('shifts')
        .select(`
            *,
            users (
                username,
                first_name,
                last_name
            )
        `)
        .gte('day', weekStart.toISOString().split('T')[0])
        .lte('day', weekEnd.toISOString().split('T')[0]);
    
    if (error) {
        console.error('Error fetching shifts:', error);
        return [];
    }
    return data;
}

async function saveShift(shiftData) {
    const { data, error } = await supabase
        .from('shifts')
        .upsert([shiftData])
        .select()
        .single();
    
    if (error) {
        console.error('Error saving shift:', error);
        return null;
    }
    return data;
}

async function deleteShift(shiftId) {
    const { error } = await supabase
        .from('shifts')
        .delete()
        .eq('id', shiftId);
    
    if (error) {
        console.error('Error deleting shift:', error);
        return false;
    }
    return true;
}

// Inklok functies
async function clockIn(userId) {
    // Controleer eerst of er al een actieve sessie is
    const { data: activeSession } = await supabase
        .from('clockings')
        .select('id')
        .eq('user_id', userId)
        .is('clock_out', null)
        .single();
    
    if (activeSession) {
        throw new Error('User is already clocked in');
    }
    
    const { data, error } = await supabase
        .from('clockings')
        .insert([{
            user_id: userId,
            clock_in: new Date().toISOString()
        }])
        .select()
        .single();
    
    if (error) {
        console.error('Error clocking in:', error);
        throw error;
    }
    return data;
}

async function clockOut(userId) {
    const { error } = await supabase
        .from('clockings')
        .update({ clock_out: new Date().toISOString() })
        .eq('user_id', userId)
        .is('clock_out', null)
        .order('clock_in', { ascending: false })
        .limit(1);
    
    if (error) {
        console.error('Error clocking out:', error);
        throw error;
    }
    return true;
}

async function getClockHistory(userId, limit = 10) {
    const { data, error } = await supabase
        .from('clockings')
        .select('*')
        .eq('user_id', userId)
        .order('clock_in', { ascending: false })
        .limit(limit);
    
    if (error) {
        console.error('Error fetching clock history:', error);
        return [];
    }
    return data;
}

async function getActiveClockSession(userId) {
    const { data, error } = await supabase
        .from('clockings')
        .select('*')
        .eq('user_id', userId)
        .is('clock_out', null)
        .order('clock_in', { ascending: false })
        .limit(1)
        .single();
    
    if (error && error.code !== 'PGRST116') { // PGRST116 = no rows returned
        console.error('Error fetching active session:', error);
        return null;
    }
    return data;
}

// Utility functies
function calculateHoursWorked(clockIn, clockOut = null) {
    const start = new Date(clockIn);
    const end = clockOut ? new Date(clockOut) : new Date();
    return (end - start) / (1000 * 60 * 60); // uren
}

function formatDate(date) {
    return new Date(date).toLocaleDateString('nl-NL');
}

function formatTime(date) {
    return new Date(date).toLocaleTimeString('nl-NL', { 
        hour: '2-digit', 
        minute: '2-digit' 
    });
}

// Export voor gebruik in andere bestanden
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        supabase,
        getUsers,
        getUserByUsername,
        createUser,
        getShiftsForWeek,
        saveShift,
        deleteShift,
        clockIn,
        clockOut,
        getClockHistory,
        getActiveClockSession,
        calculateHoursWorked,
        formatDate,
        formatTime
    };
}
