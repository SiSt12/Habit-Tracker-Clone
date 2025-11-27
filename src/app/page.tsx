'use client';

import { useEffect, useState } from 'react';
import { Plus, Settings, Trophy, BarChart3, User } from 'lucide-react';
import { api } from '@/lib/api';
import { HabitCard } from '@/components/HabitCard';
import { AddHabitModal } from '@/components/AddHabitModal';
import Link from 'next/link';

interface Habit {
  id: string;
  name: string;
  icon: string;
  color: number;
  history: Record<string, boolean>;
  archived: boolean;
}

export default function Home() {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [loading, setLoading] = useState(true);

  const fetchHabits = async () => {
    try {
      const response = await api.get<Habit[]>('/habits');
      // Filter out archived habits
      setHabits(response.data.filter(h => !h.archived));
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
    <div className="min-h-screen bg-[#0d1117] text-white p-4 md:p-8 font-sans">
      <div className="max-w-2xl mx-auto">
        <header className="flex justify-between items-center mb-10 pt-4">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-zinc-900 rounded-lg">
              <Settings size={20} className="text-zinc-400" />
            </div>
            <h1 className="text-2xl font-bold tracking-tight">Dinho Tracker</h1>
          </div>
          <div className="flex gap-3">
            <div className="p-2 bg-zinc-900 rounded-lg">
              <Trophy size={20} className="text-zinc-400" />
            </div>
            <div className="p-2 bg-zinc-900 rounded-lg">
              <BarChart3 size={20} className="text-zinc-400" />
            </div>
            <Link href="/login" className="p-2 bg-zinc-900 rounded-lg text-zinc-400 hover:text-white transition-colors">
              <User size={20} />
            </Link>
            <button
              onClick={() => setIsModalOpen(true)}
              className="p-2 bg-white text-black rounded-full hover:bg-gray-200 transition-colors"
            >
              <Plus size={24} />
            </button>
          </div>
        </header>

        {/* Global Day Header */}
        {habits.length > 0 && (
          <div className="flex justify-end px-4 mb-2">
            <div className="flex gap-2">
              {Array.from({ length: 5 }).map((_, i) => {
                const date = new Date();
                date.setDate(date.getDate() - (4 - i));
                return (
                  <div key={i} className="w-8 text-center">
                    <span className="text-[10px] text-zinc-500 font-medium uppercase">
                      {date.toLocaleDateString('en-US', { weekday: 'short' })}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {loading ? (
          <div className="flex justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
          </div>
        ) : habits.length === 0 ? (
          <div className="text-center py-12 bg-zinc-900 rounded-2xl border border-zinc-800">
            <div className="mb-4 text-6xl">🌱</div>
            <h3 className="text-xl font-semibold mb-2">No habits yet</h3>
            <p className="text-zinc-400 mb-6">Start your journey by creating your first habit.</p>
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-6 py-2 bg-white text-black font-semibold rounded-lg hover:bg-gray-200 transition-colors"
            >
              Create Habit
            </button>
          </div>
        ) : (
          <div className="flex flex-col gap-3">
            {habits.map((habit) => (
              <HabitCard key={habit.id} habit={habit} onUpdate={fetchHabits} />
            ))}
          </div>
        )}

        <AddHabitModal
          isOpen={isModalOpen}
          onClose={() => setIsModalOpen(false)}
          onAdded={fetchHabits}
        />
      </div>
    </div>
  );
}
