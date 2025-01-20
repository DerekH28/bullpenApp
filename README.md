# README for Bullpen App

## Overview

The **Bullpen App** is a Shiny-based web application designed for managing and analyzing baseball bullpen sessions. It provides tools for recording pitch data, analyzing performance, and generating reports. The application includes an admin interface for managing pitchers and sessions, a scripted bullpen session mode, and a live bullpen session mode.

----------

## Features

### Home Screen

-   **Scripted Bullpen Session**: Facilitates tracking and analysis of predefined bullpen sessions with uploaded CSV data.
-   **Live Bullpen Session**: Tracks live pitching data in real-time.
-   **Admin Page**: Manage pitchers and session data.

### Admin Page

-   **Password Protected**: Requires an admin password for access.
-   **Add New Pitcher**: Add new pitchers to the database.
-   **Delete Pitcher**: Remove existing pitchers from the database.
-   **View Pitchers**: Display a list of all pitchers in the database.
-   **View Sessions**: List all recorded sessions.

### Scripted Bullpen Session

-   Upload a CSV file containing scripted session data.
-   Navigate through rows to view pitch details.
-   Add custom pitch locations to calculate horizontal, vertical, and total distances.
-   Visualize the strike zone with pitch data overlaid.
-   Export session data as CSV or PDF.

### Live Bullpen Session

-   Upload CSV data for real-time session tracking.
-   Update recommended pitch locations and record actual pitch results.
-   Visualize strike zone data in real-time.
-   Export session data as CSV or PDF.

----------

## Installation and Setup

### Prerequisites

-   **R**: Ensure R is installed on your system.
-   **RStudio** (optional but recommended).
-   Install the required R packages:
    
    R
    
    CopyEdit
    
    `install.packages(c("shiny", "ggplot2", "readr", "DT", "DBI", "RSQLite", "grid", "png", "rmarkdown"))` 
    

### Database Setup

1.  The application uses two SQLite databases:
    -   `pitchers_db.sqlite` for managing pitcher data.
    -   `sessions_db.sqlite` for storing session data.
2.  On first run, the app initializes the databases and creates required tables if they don’t already exist.

### Running the App

1.  Save the app code as a file, e.g., `app.R`.
2.  Run the app in R or RStudio using:
    
    R
    
    CopyEdit
    
    `shiny::runApp("app.R")` 
    

----------

## Usage

### Admin Page

1.  Navigate to the Admin Page from the home screen.
2.  Enter the admin password (`admin123` by default).
3.  Use the options to manage pitchers and view session data.

### Scripted Bullpen Session

1.  Click **Scripted Bullpen Session** on the home screen.
2.  Upload a CSV file containing pitch data.
3.  Navigate through rows to view and analyze pitches.
4.  Add custom pitch points and calculate distances.
5.  Export the session report as CSV or PDF.

### Live Bullpen Session

1.  Click **Live Bullpen Session** on the home screen.
2.  Upload a CSV file for live pitch tracking.
3.  Update recommended pitch locations and log actual pitch data.
4.  Visualize live data in the strike zone.
5.  Export session reports as CSV or PDF.

----------

## CSV File Format

### Scripted Bullpen Session

-   A CSV file with the following columns:
    1.  `x_value`: X-coordinate of the pitch.
    2.  `y_value`: Y-coordinate of the pitch.
    3.  `handedness`: Batter handedness (`R` for right, `L` for left).
    4.  `count`: Pitch count (e.g., `3-2`).

### Live Bullpen Session

-   Similar to the scripted session format but used for real-time updates.

----------

## Outputs

### Reports

-   **CSV**: A detailed record of distances for each pitch.
-   **PDF**: A visually formatted session report, including strike zone plots and summary data.

----------

## Dependencies

### R Packages

-   **shiny**: For building the interactive app.
-   **ggplot2**: For plotting strike zone visualizations.
-   **readr**: For reading CSV files.
-   **DT**: For displaying interactive tables.
-   **DBI** and **RSQLite**: For database operations.
-   **grid** and **png**: For rendering batter images.
-   **rmarkdown**: For generating PDF reports.

### File Dependencies

-   **Images**: `right_handed_batter.png` and `left_handed_batter.png` for batter visualizations.
-   **Markdown Template**: `session_report.Rmd` for PDF generation.

----------

## Customization

1.  **Admin Password**: Update the `adminPassword` value in the `server` function.
2.  **PDF Template**: Modify the `session_report.Rmd` file for custom PDF layouts.
3.  **Database Paths**: Change database paths in the `dbConnect` calls.

----------

## Notes

-   Ensure batter image files are in the correct directory.
-   CSV files must adhere to the specified format for proper functionality.
