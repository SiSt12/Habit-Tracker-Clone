'use client';

import { useState, useEffect } from 'react';
import { X, Check, Archive, Trash2, Calendar as CalendarIcon } from 'lucide-react';
import * as Icons from 'lucide-react';
import { api } from '@/lib/api';
import { clsx } from 'clsx';
import { format, eachDayOfInterval, startOfMonth, endOfMonth, isSameMonth, isToday, startOfWeek, endOfWeek } from 'date-fns';

interface Habit {
    id: string;
    name: string;
    icon: string;
    color: number;
    history: Record<string, boolean>;
    archived: boolean;
}

interface EditHabitModalProps {
    habit: Habit | null;
    isOpen: boolean;
    onClose: () => void;
    onUpdated: () => void;
}

const COLORS = [
    0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7, 0xFF3F51B5, 0xFF2196F3,
    0xFF03A9F4, 0xFF00BCD4, 0xFF009688, 0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39,
    0xFFFFEB3B, 0xFFFFC107, 0xFFFF9800, 0xFFFF5722,
];

const ICONS = [
    'Activity', 'Book', 'Briefcase', 'Calendar', 'Camera', 'CheckCircle',
    'Clock', 'Code', 'Coffee', 'Droplet', 'Dumbbell', 'Edit', 'FileText',
    'Flag', 'Gift', 'Globe', 'Heart', 'Home', 'Image', 'Layers', 'Layout',
    'Map', 'MessageCircle', 'Mic', 'Moon', 'Music', 'Package', 'PenTool',
    'Phone', 'Play', 'Power', 'Printer', 'Radio', 'Save', 'Scissors',
    'Search', 'Settings', 'Share', 'Shield', 'ShoppingBag', 'Smartphone',
    'Smile', 'Speaker', 'Star', 'Sun', 'Tag', 'Target', 'Thermometer',
    'ThumbsUp', 'Tool', 'Trash', 'Truck', 'Tv', 'Umbrella', 'User', 'Video',
    'Voicemail', 'Volume2', 'Watch', 'Wifi', 'Zap'
];

export function EditHabitModal({ habit, isOpen, onClose, onUpdated }: EditHabitModalProps) {
    const [name, setName] = useState('');
    const [selectedIcon, setSelectedIcon] = useState('Activity');
    const [selectedColor, setSelectedColor] = useState(COLORS[5]);
    const [loading, setLoading] = useState(false);
    const [currentMonth, setCurrentMonth] = useState(new Date());

    useEffect(() => {
        if (habit) {
            setName(habit.name);
            setSelectedIcon(habit.icon);
            setSelectedColor(habit.color);
        }
    }, [habit]);

    if (!isOpen || !habit) return null;

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            await api.patch(`/habits/${habit.id}`, {
                name,
                icon: selectedIcon,
                color: selectedColor,
            });
            onUpdated();
            onClose();
        } catch (error) {
            console.error('Failed to update habit', error);
        } finally {
            setLoading(false);
        }
    };

    const toggleArchive = async () => {
        if (!confirm(habit.archived ? 'Restore this habit?' : 'Archive this habit?')) return;
        try {
            await api.patch(`/habits/${habit.id}/archive`);
            onUpdated();
            onClose();
        } catch (error) {
            console.error('Failed to toggle archive', error);
        }
    };

    const deleteHabit = async () => {
        if (!confirm('Delete this habit permanently?')) return;
        try {
            await api.delete(`/habits/${habit.id}`);
            onUpdated();
            onClose();
        } catch (error) {
            console.error('Failed to delete habit', error);
        }
    };

    // Calendar Logic
    const monthStart = startOfMonth(currentMonth);
    const monthEnd = endOfMonth(monthStart);
    const calendarStart = startOfWeek(monthStart);
    const calendarEnd = endOfWeek(monthEnd);

    const calendarDays = eachDayOfInterval({
        start: calendarStart,
        end: calendarEnd,
    });

    const colorHex = Color(selectedColor);

    return (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
            <div className="bg-zinc-900 rounded-2xl w-full max-w-2xl shadow-2xl max-h-[90vh] overflow-y-auto border border-zinc-800 flex flex-col md:flex-row">

                {/* Left Side: Edit Form */}
                <div className="p-6 flex-1 border-b md:border-b-0 md:border-r border-zinc-800">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-xl font-bold text-white">Edit Habit</h2>
                        <button onClick={onClose} className="text-zinc-500 hover:text-white transition-colors">
                            <X size={24} />
                        </button>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div>
                            <label className="block text-sm font-medium text-zinc-400 mb-2">Name</label>
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                className="w-full px-4 py-2 rounded-lg border border-zinc-700 bg-zinc-800 text-white focus:ring-2 focus:ring-blue-500 outline-none"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-400 mb-2">Color</label>
                            <div className="grid grid-cols-8 gap-2">
                                {COLORS.map((color) => (
                                    <button
                                        key={color}
                                        type="button"
                                        onClick={() => setSelectedColor(color)}
                                        className="w-6 h-6 rounded-full flex items-center justify-center transition-transform hover:scale-110"
                                        style={{ backgroundColor: Color(color) }}
                                    >
                                        {selectedColor === color && <Check size={12} className="text-white" />}
                                    </button>
                                ))}
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-400 mb-2">Icon</label>
                            <div className="grid grid-cols-6 gap-2 max-h-40 overflow-y-auto p-1 scrollbar-thin scrollbar-thumb-zinc-700">
                                {ICONS.map((iconName) => {
                                    // @ts-ignore
                                    const Icon = Icons[iconName];
                                    if (!Icon) return null;
                                    return (
                                        <button
                                            key={iconName}
                                            type="button"
                                            onClick={() => setSelectedIcon(iconName)}
                                            className={clsx(
                                                "p-2 rounded-lg flex items-center justify-center transition-all",
                                                selectedIcon === iconName
                                                    ? "bg-blue-500/20 text-blue-400 ring-1 ring-blue-500"
                                                    : "hover:bg-zinc-800 text-zinc-500"
                                            )}
                                        >
                                            <Icon size={18} />
                                        </button>
                                    );
                                })}
                            </div>
                        </div>

                        <div className="flex gap-3 pt-4">
                            <button
                                type="submit"
                                disabled={loading}
                                className="flex-1 py-2 px-4 bg-white text-black font-semibold rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
                            >
                                {loading ? 'Saving...' : 'Save Changes'}
                            </button>
                        </div>

                        <div className="flex gap-3 border-t border-zinc-800 pt-4">
                            <button
                                type="button"
                                onClick={toggleArchive}
                                className="flex-1 py-2 px-4 bg-zinc-800 text-zinc-300 font-medium rounded-lg hover:bg-zinc-700 transition-colors flex items-center justify-center gap-2"
                            >
                                <Archive size={16} />
                                {habit.archived ? 'Restore' : 'Archive'}
                            </button>
                            <button
                                type="button"
                                onClick={deleteHabit}
                                className="flex-1 py-2 px-4 bg-red-500/10 text-red-500 font-medium rounded-lg hover:bg-red-500/20 transition-colors flex items-center justify-center gap-2"
                            >
                                <Trash2 size={16} />
                                Delete
                            </button>
                        </div>
                    </form>
                </div>

                {/* Right Side: Calendar History */}
                <div className="p-6 flex-1 bg-zinc-900/50">
                    <div className="flex items-center justify-between mb-6">
                        <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                            <CalendarIcon size={18} className="text-zinc-400" />
                            History
                        </h3>
                        <div className="text-sm text-zinc-400 font-medium">
                            {format(currentMonth, 'MMMM yyyy')}
                        </div>
                    </div>

                    <div className="grid grid-cols-7 gap-1 text-center mb-2">
                        {['S', 'M', 'T', 'W', 'T', 'F', 'S'].map(day => (
                            <div key={day} className="text-xs text-zinc-500 font-medium py-1">{day}</div>
                        ))}
                    </div>

                    <div className="grid grid-cols-7 gap-1">
                        {calendarDays.map((day) => {
                            const dateStr = format(day, 'yyyy-MM-dd');
                            const isCompleted = habit.history[dateStr];
                            const isCurrentMonth = isSameMonth(day, currentMonth);

                            return (
                                <div
                                    key={dateStr}
                                    className={clsx(
                                        "aspect-square rounded-md flex items-center justify-center text-xs transition-colors",
                                        !isCurrentMonth && "opacity-20",
                                        isCompleted
                                            ? "text-white font-bold"
                                            : "text-zinc-600 bg-zinc-800/50"
                                    )}
                                    style={{ backgroundColor: isCompleted ? colorHex : undefined }}
                                >
                                    {format(day, 'd')}
                                </div>
                            );
                        })}
                    </div>
                </div>
            </div>
        </div>
    );
}

function Color(intColor: number): string {
    const hex = (intColor >>> 0).toString(16).padStart(8, '0');
    return `#${hex.substring(2)}`;
}
