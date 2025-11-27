'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import { Plus, Settings, Archive, LogOut } from 'lucide-react';
import { api } from '@/lib/api';
import { HabitCard } from '@/components/HabitCard';
import { AddHabitModal } from '@/components/AddHabitModal';
import { supabase } from '@/lib/supabase';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import type { Habit } from '@/types';

export default function Home() {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [showSettingsMenu, setShowSettingsMenu] = useState(false);
  const router = useRouter();
  const settingsMenuRef = useRef<HTMLDivElement>(null);

  const fetchHabits = useCallback(async () => {
    try {
      const response = await api.get<Habit[]>('/habits');
      // Filter out archived habits
      setHabits(response.data.filter(h => !h.archived));
    } catch (error) {
      console.error('Failed to fetch habits', error);
    } finally {
      setLoading(false);
    }
  }, []);

  const handleLogout = useCallback(async () => {
    await supabase.auth.signOut();
    router.push('/login');
  }, [router]);

  const openModal = useCallback(() => setIsModalOpen(true), []);
  const closeModal = useCallback(() => setIsModalOpen(false), []);
  const toggleSettingsMenu = useCallback(() => setShowSettingsMenu(prev => !prev), []);

  useEffect(() => {
    // Check authentication status
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();

      if (!session) {
        router.push('/login');
        return;
      }

      setIsAuthenticated(true);
      fetchHabits();
    };

    checkAuth();
  }, [router, fetchHabits]);

  // Close settings menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (settingsMenuRef.current && !settingsMenuRef.current.contains(event.target as Node)) {
        setShowSettingsMenu(false);
      }
    };

    if (showSettingsMenu) {
      document.addEventListener('mousedown', handleClickOutside);
      return () => document.removeEventListener('mousedown', handleClickOutside);
    }
  }, [showSettingsMenu]);

  return (
    <div className="min-h-screen bg-[#0d1117] text-white p-4 md:p-8 font-sans">
      <div className="max-w-2xl mx-auto">
        <header className="flex justify-between items-center mb-10 pt-4">
          <div className="flex items-center gap-2">
            <div className="relative" ref={settingsMenuRef}>
              <button
                onClick={toggleSettingsMenu}
                className="p-2 bg-zinc-900 rounded-lg hover:bg-zinc-800 transition-colors"
              >
                <Settings size={20} className="text-zinc-400" />
              </button>
              {showSettingsMenu && (
                <div className="absolute top-12 left-0 bg-zinc-900 border border-zinc-800 rounded-lg shadow-xl z-50 min-w-[150px]">
                  <button
                    onClick={handleLogout}
                    className="w-full px-4 py-2 text-left text-zinc-400 hover:text-white hover:bg-zinc-800 transition-colors flex items-center gap-2 rounded-lg"
                  >
                    <LogOut size={16} />
                    Logout
                  </button>
                </div>
              )}
            </div>
            <h1 className="text-2xl font-bold tracking-tight">Dinho Tracker</h1>
          </div>
          <div className="flex gap-3">
            <Link href="/archive" className="p-2 bg-zinc-900 rounded-lg text-zinc-400 hover:text-white transition-colors">
              <Archive size={20} />
            </Link>
            <button
              onClick={openModal}
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
              onClick={openModal}
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
          onClose={closeModal}
          onAdded={fetchHabits}
        />
      </div>
    </div>
  );
}
