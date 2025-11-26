# Habit Tracker

A full-stack habit tracking application built with **NestJS** and **Next.js**.

## Architecture

-   **Backend**: NestJS (Node.js framework)
    -   REST API
    -   SQLite Database
    -   TypeORM
-   **Frontend**: Next.js (React framework)
    -   Tailwind CSS
    -   Lucide Icons

## Getting Started

### Prerequisites
-   Node.js (v18+)
-   npm

### Installation

1.  **Backend Setup**
    ```bash
    cd backend
    npm install
    npm run start:dev
    ```
    The API will run on `http://localhost:3000`.

2.  **Frontend Setup**
    ```bash
    cd frontend
    npm install
    npm run dev
    ```
    The application will run on `http://localhost:3001`.

## Features
-   Create new habits with custom icons and colors.
-   Track daily progress.
-   Archive and restore habits.
-   Delete habits.
