import { createClient } from '@supabase/supabase-js';

const supabaseUrl = 'https://iddnpicitcngcdjqtbki.supabase.co';
const supabaseKey = 'sb_publishable_t_7K4FslEmnuUwlXV96RbQ_7G-gbFsN';

export const supabase = createClient(supabaseUrl, supabaseKey);
