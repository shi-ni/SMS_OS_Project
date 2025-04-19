#!/bin/bash

#############################################################################
# Student Management System (SMS) - Bash Script
# 
# Description:
#   A simple command-line system for teachers to manage student records and
#   for students to view their grades. Data is stored in text files.
#
# Key Features:
#   - Teacher: Add/delete students, update marks, calculate grades.
#   - Student: View grades using Roll No and password.
#   - Auto-saves data to students.txt and student_logins.txt.
#   - Prevents duplicate roll numbers.
#   - Teachers set custom passwords for students.
#
# Usage:
#   1. Run the script: ./sms.sh
#   2. Default teacher login: admin / admin123
#   3. Teachers set student passwords during enrollment.
#
# File Structure:
#   - students.txt: Stores student records (Roll No, Name, Marks, Grade)
#   - student_logins.txt: Stores student credentials (Roll No, Password)
#   - teachers.txt: Stores teacher credentials (Username, Password)
#
# Note: For first-time use, the script auto-creates a default teacher account.
#############################################################################

# Files
STUDENTS_FILE="students.txt"
TEACHERS_FILE="teachers.txt"
LOGINS_FILE="student_logins.txt"

# Create files if they don't exist
touch "$STUDENTS_FILE" "$TEACHERS_FILE" "$LOGINS_FILE"

# ====================== TEACHER FUNCTIONS ======================

teacher_login() {
    echo -n "Teacher Username: "
    read username
    echo -n "Teacher Password: "
    read -s password
    echo

    # Check if teacher exists
    found=0
    while IFS=, read -r user pass; do
        if [ "$user" = "$username" ] && [ "$pass" = "$password" ]; then
            found=1
            break
        fi
    done < "$TEACHERS_FILE"

    if [ $found -eq 1 ]; then
        teacher_menu
    else
        echo "Invalid login!"
    fi
}

add_student() {
    echo -e "\n--- Add Student ---"
    
    # Check for existing roll number
    while true; do
        echo -n "Roll No: "
        read roll_no
        if [ $roll_no -lt 0  ]; then
        echo "roll no is less than 0"
        break
        fi
    
        # Check if roll number already exists
        exists=0
        while IFS=, read -r r_no name marks; do
            if [ "$r_no" = "$roll_no" ]; then
                exists=1
                break
            fi
        done < "$STUDENTS_FILE"
        
        if [ $exists -eq 1 ]; then
            echo "Error: Roll No $roll_no already exists! Please enter a different Roll No."
        else
            break
        fi
    done

    echo -n "Name: "
    read name
    echo -n "Marks: "
    read marks
    if [$name[0] -lt '-' ]; then
    
    echo "name cannot be negative"
    break
    fi
    
    if [ $Marks -lt 0  ]; then
    echo "marks cannot be less than 0"
    break
    fi

    # Set password with validation
    while true; do
        echo -n "Set password for $name: "
        read -s password
        echo
        if [ -z "$password" ]; then
            echo "Password cannot be empty!"
        else
            break
        fi
    done

    # Save to students.txt
    echo "$roll_no,$name,$marks" >> "$STUDENTS_FILE"

    # Save to logins file
    echo "$roll_no,$password,$roll_no" >> "$LOGINS_FILE"

    echo "Student added successfully!"
}

delete_student() {
    echo -n "Enter Roll No to delete: "
    read roll_no

    # Create a temp file without the student
    temp_file=$(mktemp)
    while IFS=, read -r r_no name marks grade gpa; do
        if [ "$r_no" != "$roll_no" ]; then
            echo "$r_no,$name,$marks,$grade,$gpa" >> "$temp_file"
        fi
    done < "$STUDENTS_FILE"

    mv "$temp_file" "$STUDENTS_FILE"

    # Also delete from logins
    temp_file=$(mktemp)
    while IFS=, read -r user pass r_no; do
        if [ "$r_no" != "$roll_no" ]; then
            echo "$user,$pass,$r_no" >> "$temp_file"
        fi
    done < "$LOGINS_FILE"

    mv "$temp_file" "$LOGINS_FILE"

    echo "Student deleted!"
}

assign_marks() {
    echo -n "Enter Roll No to assign marks: "
    read roll_no
    echo -n "Enter new marks: "
    read marks

    local input_file="$STUDENTS_FILE"
    local output_file="temp"

    > "$output_file"  

    while IFS=',' read -r id name current_marks
    do
        if [[ "$id" -eq "$roll_no" ]]; then
            echo "$id,$name,$marks" >> "$output_file"
        else
            echo "$id,$name,$current_marks" >> "$output_file"
        fi
    done < "$input_file"

    mv "$output_file" "$input_file"
    echo "Marks updated."
}

calculate_cgpa() {
    local output_file="temp"
    local input_file="$STUDENTS_FILE"
    > "$output_file"  # Empty or create temp file

    while IFS=',' read -r r_no name marks grade gpa
    do
        gpa=0.0
        if (( marks >= 85 )); then
            gpa=4.0
        elif (( marks >= 80 )); then
            gpa=3.7
        elif (( marks >= 75 )); then
            gpa=3.3
        elif (( marks >= 70 )); then
            gpa=3.0
        elif (( marks >= 65 )); then
            gpa=2.7
        elif (( marks >= 60 )); then
            gpa=2.3
        elif (( marks >= 55 )); then
            gpa=2.0
        elif (( marks >= 50 )); then
            gpa=1.7
        elif (( marks >= 45 )); then
            gpa=1.0
        else
            gpa=0.0
        fi

        echo "$r_no,$name,$marks,$grade,$gpa" >> "$output_file"
    done < "$input_file"

    mv "$output_file" "$input_file"
    echo "CGPA calculated."
}

calculate_grades() {
    temp_file=$(mktemp)
    while IFS=, read -r roll_no name marks grade; do
        if [ -z "$marks" ]; then
            grade="N/A"
        elif [ "$marks" -ge 85 ]; then
            grade="A"
        elif [ "$marks" -ge 80 ]; then
            grade="A-"
        elif [ "$marks" -ge 75 ]; then
            grade="B+"
        elif [ "$marks" -ge 70 ]; then
            grade="B"
        elif [ "$marks" -ge 65 ]; then
            grade="B-"
        elif [ "$marks" -ge 60 ]; then
            grade="C+"
        elif [ "$marks" -ge 55 ]; then
            grade="C"
        elif [ "$marks" -ge 50 ]; then
            grade="C-"
        elif [ "$marks" -ge 45 ]; then
            grade="D+"
        else
            grade="F"
        fi
        echo "$roll_no,$name,$marks,$grade" >> "$temp_file"
    done < "$STUDENTS_FILE"

    mv "$temp_file" "$STUDENTS_FILE"
    echo "Grades calculated!"
    calculate_cgpa 
}

sort_by_cgpa() {
    echo -e "\n--- Students Sorted by CGPA (Highest First) ---"
    echo "RollNo | Name   | Marks | Grade | GPA"
    echo "-------------------------------------"
    # Sort numerically by GPA (5th field) in reverse order
    sort -t',' -k5,5 -nr "$STUDENTS_FILE" | while IFS=',' read -r roll_no name marks grade gpa
    do
        printf "%-7s| %-6s | %-5s | %-5s | %-4s\n" "$roll_no" "$name" "$marks" "$grade" "$gpa"
    done
}


show_passing_students() {
    echo "Good Students Who Passed:"
    echo "-----------------------"
    
    # Read the file line by line
    while IFS=',' read -r roll name marks grade gpa
    do
        # Check if grade exists and isn't F
        if [ "$grade" != "F" ] && [ -n "$grade" ]; then
            echo "$roll | $name | $marks | $grade | $gpa"
        fi
    done < "$STUDENTS_FILE"
    
    echo "-----------------------"
}

show_failing_students() {
    echo "Bad Students Who Failed:"
    echo "----------------------"
    
    # Read the file line by line
    while IFS=',' read -r roll name marks grade gpa
    do
        # Check if grade is F
        if [ "$grade" = "F" ]; then
            echo "$roll | $name | $marks | $grade | $gpa"
        fi
    done < "$STUDENTS_FILE"
    
    echo "----------------------"
}


view_students() {
    echo -e "\n--- Student List ---"
    echo "Roll No | Name       | Marks | Grade | GPA"
    echo "------------------------------------------"
    while IFS=, read -r roll_no name marks grade gpa; do
        # If GPA doesn't exist, show "N/A"
        [ -z "$gpa" ] && gpa="N/A"
        printf "%-8s| %-10s | %-5s | %-5s | %-4s\n" "$roll_no" "$name" "$marks" "$grade" "$gpa"
    done < "$STUDENTS_FILE"
}

# ====================== STUDENT FUNCTIONS ======================

student_login() {
    echo -n "Student Username (Roll No): "
    read username
    echo -n "Password: "
    read -s password
    echo

    found=0
    while IFS=, read -r user pass r_no; do
        if [ "$user" = "$username" ] && [ "$pass" = "$password" ]; then
            found=1
            break
        fi
    done < "$LOGINS_FILE"

    if [ $found -eq 1 ]; then
        student_menu "$r_no"
    else
        echo "Invalid login!"
    fi
}

view_grades() {
    roll_no=$1
    while IFS=, read -r r_no name marks grade gpa; do
        if [ "$r_no" = "$roll_no" ]; then
            echo -e "\n--- Your Grades ---"
            echo "Name: $name"
            echo "Marks: $marks"
            echo "Grade: $grade"
            echo "gpa: $gpa"

            return
        fi
    done < "$STUDENTS_FILE"
    echo "Record not found!"
}



# ====================== MENUS ======================

teacher_menu() {
   while true; do
    echo -e "\n--- Teacher Menu ---"
    echo "1. Add new student"
    echo "2. Remove student"
    echo "3. Calculate grades"
    echo "4. Show all students"
    echo "5. Give marks to student"
    echo "6. Calculate GPA"
    echo "7. Show passing students"
    echo "8. Show failing students" 
    echo "9. Sort by GPA"
    echo "10. Exit"
    echo -n "What do you want to do? (1-10): "
    read choice

    case $choice in
        1) add_student ;;
        2) delete_student ;;
        3) calculate_grades ;;
        4) view_students ;;
        5) assign_marks ;;
        6) calculate_cgpa ;;
        7) show_passing_students ;;
        8) show_failing_students ;;
        9) sort_by_cgpa ;;
        10) break ;;
        *) echo "Oops! Try again with number 1-10" ;;
    esac
done
}

student_menu() {
    roll_no=$1
    while true; do
        echo -e "\n--- Student Menu ---"
        echo "1. View Grades/GPA"
        echo "2. Logout"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1) view_grades "$roll_no" ;;
            2) break ;;
            *) echo "Invalid option!" ;;
        esac
    done
}

main_menu() {
    # Create default teacher if file is empty
    if [ ! -s "$TEACHERS_FILE" ]; then
        echo "admin,admin123" > "$TEACHERS_FILE"
    fi

    while true; do
        echo -e "\n--- Student Management System ---"
        echo "1. Teacher Login"
        echo "2. Student Login"
        echo "3. Exit"
        echo -n "Choose an option: "
        read choice

        case $choice in
            1) teacher_login ;;
            2) student_login ;;
            3) exit 0 ;;
            *) echo "Invalid option!" ;;
        esac
    done
}

# Start the program
main_menu