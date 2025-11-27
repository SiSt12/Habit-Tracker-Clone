'use client';

import { useState, useEffect } from 'react';
import { X, Check } from 'lucide-react';
import * as Icons from 'lucide-react';
import { api } from '@/lib/api';
import { cn, colorToHex } from '@/lib/utils';
import { COLORS, ICONS } from '@/lib/constants';

interface AddHabitModalProps {
    isOpen: boolean;
    onClose: () => void;
    onAdded: () => void;
}

export function AddHabitModal({ isOpen, onClose, onAdded }: AddHabitModalProps) {
    const [name, setName] = useState('');
    const [selectedIcon, setSelectedIcon] = useState('Activity');
    const [selectedColor, setSelectedColor] = useState<number>(COLORS[5]);
    const [loading, setLoading] = useState(false);

    // Handle ESC key to close modal
    useEffect(() => {
        const handleEscape = (e: KeyboardEvent) => {
            if (e.key === 'Escape' && isOpen) {
                onClose();
            }
        };

        document.addEventListener('keydown', handleEscape);
        return () => document.removeEventListener('keydown', handleEscape);
    }, [isOpen, onClose]);

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

    const handleBackdropClick = (e: React.MouseEvent) => {
        if (e.target === e.currentTarget) {
            onClose();
        }
    };

    return (
        <div
            onClick={handleBackdropClick}
            className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4 backdrop-blur-sm"
        >
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
                                        style={{ backgroundColor: colorToHex(color) }}
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
                                            className={cn(
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
