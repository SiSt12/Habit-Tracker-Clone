import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merge class names with tailwind-merge
 */
export function cn(...inputs: ClassValue[]) {
    return twMerge(clsx(inputs));
}

/**
 * Convert integer color to hex string
 */
export function colorToHex(intColor: number): string {
    const hex = (intColor >>> 0).toString(16).padStart(8, '0');
    return `#${hex.substring(2)}`;
}

/**
 * Show toast notification (simple implementation)
 */
export function showToast(message: string, type: 'success' | 'error' = 'success') {
    // For now, use alert - can be replaced with a proper toast library later
    if (type === 'error') {
        console.error(message);
    }
    // Could integrate react-hot-toast or similar in the future
}
