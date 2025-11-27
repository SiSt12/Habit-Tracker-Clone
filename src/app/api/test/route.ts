import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

export async function GET() {
    try {
        // Test 1: Check if we can connect to Supabase
        const { data: testData, error: testError } = await supabase
            .from('habits')
            .select('count');

        if (testError) {
            return NextResponse.json({
                success: false,
                test: 'select_count',
                error: testError.message,
                details: testError
            });
        }

        // Test 2: Get current user
        const { data: { session } } = await supabase.auth.getSession();

        return NextResponse.json({
            success: true,
            message: 'Supabase connection working',
            hasSession: !!session,
            userId: session?.user?.id
        });
    } catch (error: any) {
        return NextResponse.json({
            success: false,
            error: error.message,
            stack: error.stack
        });
    }
}
