export interface Habit {
    id: string;
    name: string;
    icon: string;
    color: number;
    history: Record<string, boolean>;
    archived: boolean;
}

export interface HabitHistory {
    [date: string]: boolean;
}

export interface User {
    id: string;
    email: string;
}
