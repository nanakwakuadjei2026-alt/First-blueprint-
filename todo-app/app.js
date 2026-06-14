// ============================================================================
// TO-DO LIST APPLICATION - JAVASCRIPT
// ============================================================================

class TodoApp {
    constructor() {
        this.todos = [];
        this.currentFilter = 'all';
        this.storageKey = 'todos_v1';
        
        // DOM Elements
        this.todoInput = document.getElementById('todoInput');
        this.addBtn = document.getElementById('addBtn');
        this.todoList = document.getElementById('todoList');
        this.emptyState = document.getElementById('emptyState');
        this.clearCompletedBtn = document.getElementById('clearCompletedBtn');
        this.clearAllBtn = document.getElementById('clearAllBtn');
        this.totalTasksEl = document.getElementById('totalTasks');
        this.completedTasksEl = document.getElementById('completedTasks');
        this.remainingTasksEl = document.getElementById('remainingTasks');
        this.filterButtons = document.querySelectorAll('.filter-btn');
        
        this.init();
    }

    // ========================================================================
    // INITIALIZATION
    // ========================================================================

    init() {
        this.loadFromStorage();
        this.attachEventListeners();
        this.render();
    }

    attachEventListeners() {
        // Add button click
        this.addBtn.addEventListener('click', () => this.addTodo());
        
        // Enter key in input
        this.todoInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.addTodo();
        });
        
        // Clear buttons
        this.clearCompletedBtn.addEventListener('click', () => this.clearCompleted());
        this.clearAllBtn.addEventListener('click', () => this.clearAll());
        
        // Filter buttons
        this.filterButtons.forEach(btn => {
            btn.addEventListener('click', (e) => this.setFilter(e.target.dataset.filter));
        });
    }

    // ========================================================================
    // CRUD OPERATIONS
    // ========================================================================

    /**
     * Add a new todo
     */
    addTodo() {
        const text = this.todoInput.value.trim();
        
        if (!text) {
            this.showAlert('Please enter a task!');
            return;
        }
        
        // Check for duplicates
        if (this.todos.some(todo => todo.text.toLowerCase() === text.toLowerCase())) {
            this.showAlert('This task already exists!');
            return;
        }
        
        const todo = {
            id: Date.now(),
            text: text,
            completed: false,
            createdAt: new Date().toISOString()
        };
        
        this.todos.unshift(todo);
        this.todoInput.value = '';
        this.saveToStorage();
        this.render();
        this.todoInput.focus();
    }

    /**
     * Toggle todo completion status
     */
    toggleTodo(id) {
        const todo = this.todos.find(t => t.id === id);
        if (todo) {
            todo.completed = !todo.completed;
            this.saveToStorage();
            this.render();
        }
    }

    /**
     * Delete a todo
     */
    deleteTodo(id) {
        this.todos = this.todos.filter(t => t.id !== id);
        this.saveToStorage();
        this.render();
    }

    /**
     * Clear all completed todos
     */
    clearCompleted() {
        const completedCount = this.todos.filter(t => t.completed).length;
        
        if (completedCount === 0) {
            this.showAlert('No completed tasks to clear!');
            return;
        }
        
        if (confirm(`Clear ${completedCount} completed task(s)?`)) {
            this.todos = this.todos.filter(t => !t.completed);
            this.saveToStorage();
            this.render();
        }
    }

    /**
     * Clear all todos
     */
    clearAll() {
        if (this.todos.length === 0) {
            this.showAlert('No tasks to clear!');
            return;
        }
        
        if (confirm('Are you sure you want to delete all tasks? This cannot be undone.')) {
            this.todos = [];
            this.saveToStorage();
            this.render();
        }
    }

    // ========================================================================
    // FILTERING
    // ========================================================================

    /**
     * Set the current filter
     */
    setFilter(filter) {
        this.currentFilter = filter;
        this.updateFilterButtons();
        this.render();
    }

    /**
     * Get filtered todos based on current filter
     */
    getFilteredTodos() {
        switch (this.currentFilter) {
            case 'active':
                return this.todos.filter(t => !t.completed);
            case 'completed':
                return this.todos.filter(t => t.completed);
            case 'all':
            default:
                return this.todos;
        }
    }

    /**
     * Update active filter button
     */
    updateFilterButtons() {
        this.filterButtons.forEach(btn => {
            btn.classList.toggle('active', btn.dataset.filter === this.currentFilter);
        });
    }

    // ========================================================================
    // LOCAL STORAGE
    // ========================================================================

    /**
     * Save todos to local storage
     */
    saveToStorage() {
        try {
            localStorage.setItem(this.storageKey, JSON.stringify(this.todos));
        } catch (error) {
            console.error('Error saving to localStorage:', error);
            this.showAlert('Failed to save tasks. Please check your storage.');
        }
    }

    /**
     * Load todos from local storage
     */
    loadFromStorage() {
        try {
            const stored = localStorage.getItem(this.storageKey);
            this.todos = stored ? JSON.parse(stored) : [];
        } catch (error) {
            console.error('Error loading from localStorage:', error);
            this.todos = [];
        }
    }

    /**
     * Export todos as JSON
     */
    exportTodos() {
        const dataStr = JSON.stringify(this.todos, null, 2);
        const dataBlob = new Blob([dataStr], { type: 'application/json' });
        const url = URL.createObjectURL(dataBlob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `todos_${new Date().toISOString().split('T')[0]}.json`;
        link.click();
        URL.revokeObjectURL(url);
    }

    /**
     * Import todos from JSON
     */
    importTodos(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const imported = JSON.parse(e.target.result);
                if (Array.isArray(imported)) {
                    this.todos = [...imported, ...this.todos];
                    this.saveToStorage();
                    this.render();
                    this.showAlert('Tasks imported successfully!');
                } else {
                    this.showAlert('Invalid file format!');
                }
            } catch (error) {
                this.showAlert('Error importing file!');
            }
        };
        reader.readAsText(file);
    }

    // ========================================================================
    // RENDERING
    // ========================================================================

    /**
     * Render the entire application
     */
    render() {
        this.renderTodoList();
        this.updateStats();
        this.toggleEmptyState();
    }

    /**
     * Render the todo list
     */
    renderTodoList() {
        const filtered = this.getFilteredTodos();
        this.todoList.innerHTML = '';
        
        filtered.forEach(todo => {
            this.todoList.appendChild(this.createTodoElement(todo));
        });
    }

    /**
     * Create a todo list item element
     */
    createTodoElement(todo) {
        const li = document.createElement('li');
        li.className = `todo-item ${todo.completed ? 'completed' : ''}`;
        li.setAttribute('data-id', todo.id);
        
        const checkbox = document.createElement('input');
        checkbox.type = 'checkbox';
        checkbox.className = 'checkbox';
        checkbox.checked = todo.completed;
        checkbox.addEventListener('change', () => this.toggleTodo(todo.id));
        
        const text = document.createElement('span');
        text.className = 'todo-text';
        text.textContent = todo.text;
        
        const deleteBtn = document.createElement('button');
        deleteBtn.className = 'delete-btn';
        deleteBtn.textContent = 'Delete';
        deleteBtn.addEventListener('click', () => this.deleteTodo(todo.id));
        
        li.appendChild(checkbox);
        li.appendChild(text);
        li.appendChild(deleteBtn);
        
        return li;
    }

    /**
     * Update statistics
     */
    updateStats() {
        const total = this.todos.length;
        const completed = this.todos.filter(t => t.completed).length;
        const remaining = total - completed;
        
        this.totalTasksEl.textContent = total;
        this.completedTasksEl.textContent = completed;
        this.remainingTasksEl.textContent = remaining;
    }

    /**
     * Toggle empty state display
     */
    toggleEmptyState() {
        const isEmpty = this.getFilteredTodos().length === 0;
        this.emptyState.classList.toggle('show', isEmpty);
    }

    // ========================================================================
    // UTILITIES
    // ========================================================================

    /**
     * Show alert message
     */
    showAlert(message) {
        alert(message);
    }

    /**
     * Get completion percentage
     */
    getCompletionPercentage() {
        if (this.todos.length === 0) return 0;
        const completed = this.todos.filter(t => t.completed).length;
        return Math.round((completed / this.todos.length) * 100);
    }

    /**
     * Get todos by date range
     */
    getTodosByDateRange(startDate, endDate) {
        return this.todos.filter(todo => {
            const createdAt = new Date(todo.createdAt);
            return createdAt >= startDate && createdAt <= endDate;
        });
    }

    /**
     * Search todos
     */
    searchTodos(query) {
        return this.todos.filter(todo => 
            todo.text.toLowerCase().includes(query.toLowerCase())
        );
    }
}

// ============================================================================
// INITIALIZE APP
// ============================================================================

let app;

document.addEventListener('DOMContentLoaded', () => {
    app = new TodoApp();
});
