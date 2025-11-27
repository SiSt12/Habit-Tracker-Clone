'use client';

import { useEffect, useState } from 'react';
import { ArrowLeft } from 'lucide-react';
import { api } from '@/lib/api';
import { HabitCard } from '@/components/HabitCard';
import Link from 'next/link';

interface Habit {
    id: string;
    name: string;
    icon: string;
    color: number;
    history: Record<string, boolean>;
    archived: boolean;
}

export default function ArchivePage() {
    const [habits, setHabits] = useState<Habit[]>([]);
    const [loading, setLoading] = useState(true);

    const fetchHabits = async () => {
        try {
            const response = await api.get<Habit[]>('/habits');
            // Filter only archived habits
            setHabits(response.data.filter(h => h.archived));
        } catch (error) {
            console.error('Failed to fetch habits', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchHabits();
    }, []);

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white p-4 md:p-8">
            <div className="max-w-4xl mx-auto">
                <header className="flex items-center gap-4 mb-8">
                    <Link
                        href="/"
                        className="p-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-full transition-colors"
                    >
                        <ArrowLeft size={24} />
                    </Link>
                    <div>
                        <h1 className="text-3xl font-bold">Archived Habits</h1>
                        <p className="text-gray-500 dark:text-gray-400">Habits you've paused or completed.</p>
                    </div>
                </header>

                {loading ? (
                    <div className="flex justify-center py-12">
                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                    </div>
                ) : habits.length === 0 ? (
                    <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
                        <div className="mb-4 text-6xl">📦</div>
                        <h3 className="text-xl font-semibold mb-2">No archived habits</h3>
                        <p className="text-gray-500 dark:text-gray-400">Archived habits will appear here.</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {habits.map((habit) => (
                            <HabitCard key={habit.id} habit={habit} onUpdate={fetchHabits} />
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
