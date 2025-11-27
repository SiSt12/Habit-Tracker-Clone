'use client';

import { useState } from 'react';
import { format, subDays } from 'date-fns';
import * as Icons from 'lucide-react';
import { api } from '@/lib/api';
import { twMerge } from 'tailwind-merge';
import { EditHabitModal } from './EditHabitModal';

interface Habit {
    id: string;
    name: string;
    icon: string;
    color: number;
    history: Record<string, boolean>;
    archived: boolean;
}

interface HabitCardProps {
    habit: Habit;
    onUpdate: () => void;
}

export function HabitCard({ habit, onUpdate }: HabitCardProps) {
    const [loading, setLoading] = useState(false);
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [optimisticHistory, setOptimisticHistory] = useState<Record<string, boolean>>(habit.history);

    const toggleHistory = async (date: Date, e: React.MouseEvent) => {
        e.stopPropagation(); // Prevent opening edit modal
        if (loading) return;

        const dateStr = format(date, 'yyyy-MM-dd');
        const newValue = !optimisticHistory[dateStr];

        // Optimistic update - change UI immediately
        setOptimisticHistory(prev => ({ ...prev, [dateStr]: newValue }));
        setLoading(true);

        const newHistory = { ...habit.history, [dateStr]: newValue };

        try {
            await api.patch(`/habits/${habit.id}/history`, { history: newHistory });
            onUpdate();
        } catch (error) {
            console.error('Failed to update history', error);
            // Rollback on error
            setOptimisticHistory(habit.history);
        } finally {
            setLoading(false);
        }
    };

    const last5Days = Array.from({ length: 5 }).map((_, i) => subDays(new Date(), 4 - i));

    // @ts-ignore
    const IconComponent = Icons[habit.icon] || Icons.Activity;
    const colorHex = Color(habit.color);

    return (
        <>
            <div
                onClick={() => setIsEditModalOpen(true)}
                className="bg-zinc-900 rounded-2xl p-4 flex items-center justify-between group cursor-pointer hover:bg-zinc-800/80 transition-colors"
            >
                {/* Left Side: Icon and Name */}
                <div className="flex items-center gap-4">
                    <div
                        className="w-12 h-12 rounded-xl flex items-center justify-center text-white/90"
                        style={{ backgroundColor: `${colorHex}40` }}
                    >
                        <IconComponent size={24} style={{ color: colorHex }} />
                    </div>
                    <h3 className="font-medium text-lg text-white">{habit.name}</h3>
                </div>

                {/* Right Side: History Grid */}
                <div className="flex gap-2">
                    {last5Days.map((date) => {
                        const dateStr = format(date, 'yyyy-MM-dd');
                        const isCompleted = optimisticHistory[dateStr];

                        return (
                            <button
                                key={dateStr}
                                onClick={(e) => toggleHistory(date, e)}
                                className={twMerge(
                                    "w-8 h-8 rounded-lg transition-all duration-200",
                                    isCompleted
                                        ? "opacity-100"
                                        : "bg-zinc-800 hover:bg-zinc-700"
                                )}
                                style={{ backgroundColor: isCompleted ? colorHex : undefined }}
                                title={format(date, 'EEE, MMM d')}
                            />
                        );
                    })}
                </div>
            </div>

            <EditHabitModal
                habit={habit}
                isOpen={isEditModalOpen}
                onClose={() => setIsEditModalOpen(false)}
                onUpdated={onUpdate}
            />
        </>
    );
}

function Color(intColor: number): string {
    const hex = (intColor >>> 0).toString(16).padStart(8, '0');
    return `#${hex.substring(2)}`;
}
