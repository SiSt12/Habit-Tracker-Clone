import axios from 'axios';
import { supabase } from './supabase';

export const api = axios.create({
    baseURL: '/habit/api',
});

api.interceptors.request.use(async (config) => {
    const { data: { session } } = await supabase.auth.getSession();
    console.log('API Request - Session:', session ? 'Found' : 'Not found', 'Token:', session?.access_token?.substring(0, 20) + '...');
    if (session?.access_token) {
        config.headers.Authorization = `Bearer ${session.access_token}`;
    }
    return config;
});
