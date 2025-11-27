'use client';

import { useState } from 'react';
import { X, Check } from 'lucide-react';
import * as Icons from 'lucide-react';
import { api } from '@/lib/api';

interface AddHabitModalProps {
    isOpen: boolean;
    onClose: () => void;
    onAdded: () => void;
}

const COLORS = [
    0xFFF44336, // Red
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF03A9F4, // Light Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Green
    0xFF8BC34A, // Light Green
    0xFFCDDC39, // Lime
    0xFFFFEB3B, // Yellow
    0xFFFFC107, // Amber
    0xFFFF9800, // Orange
    0xFFFF5722, // Deep Orange
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

export function AddHabitModal({ isOpen, onClose, onAdded }: AddHabitModalProps) {
    const [name, setName] = useState('');
    const [selectedIcon, setSelectedIcon] = useState('Activity');
    const [selectedColor, setSelectedColor] = useState(COLORS[5]);
    const [loading, setLoading] = useState(false);

    if (!isOpen) return null;

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        try {
            await api.post('/habits', {
                name,
                icon: selectedIcon,
                color: selectedColor,
            });
            onAdded();
            onClose();
            setName('');
            setSelectedIcon('Activity');
            setSelectedColor(COLORS[5]);
        } catch (error) {
            console.error('Failed to create habit', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4 backdrop-blur-sm">
            <div className="bg-zinc-900 rounded-2xl w-full max-w-md shadow-xl max-h-[90vh] overflow-y-auto border border-zinc-800">
                <div className="p-6">
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-2xl font-bold text-white">New Habit</h2>
                        <button onClick={onClose} className="text-zinc-500 hover:text-white transition-colors">
                            <X size={24} />
                        </button>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div>
                            <label className="block text-sm font-medium text-zinc-400 mb-2">
                                Name
                            </label>
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                className="w-full px-4 py-2 rounded-lg border border-zinc-700 bg-zinc-800 text-white focus:ring-2 focus:ring-blue-500 outline-none"
                                placeholder="e.g., Read 30 mins"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-400 mb-2">
                                Color
                            </label>
                            <div className="grid grid-cols-8 gap-2">
                                {COLORS.map((color) => (
                                    <button
                                        key={color}
                                        type="button"
                                        onClick={() => setSelectedColor(color)}
                                        className="w-8 h-8 rounded-full flex items-center justify-center transition-transform hover:scale-110"
                                        style={{ backgroundColor: Color(color) }}
                                    >
                                        {selectedColor === color && <Check size={16} className="text-white" />}
                                    </button>
                                ))}
                            </div>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-zinc-400 mb-2">
                                Icon
                            </label>
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
                                            <Icon size={20} />
                                        </button>
                                    );
                                })}
                            </div>
                        </div>

                        <button
                            type="submit"
                            disabled={loading}
                            className="w-full py-3 px-4 bg-white text-black font-semibold rounded-lg hover:bg-gray-200 transition-colors disabled:opacity-50"
                        >
                            {loading ? 'Creating...' : 'Create Habit'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}

function clsx(...classes: (string | boolean | undefined)[]) {
    return classes.filter(Boolean).join(' ');
}

function Color(intColor: number): string {
    const hex = (intColor >>> 0).toString(16).padStart(8, '0');
    return `#${hex.substring(2)}`;
}
