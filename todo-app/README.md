# To-Do List Application with Local Storage

A modern, feature-rich to-do list application built with vanilla HTML, CSS, and JavaScript. All data is persisted using browser local storage.

## 🎯 Features

### Core Features
- ✅ **Add Tasks** - Quickly add new to-do items
- ✅ **Mark Complete** - Check off completed tasks
- ✅ **Delete Tasks** - Remove individual tasks
- ✅ **Filter Tasks** - View All, Active, or Completed tasks
- ✅ **Local Storage** - Automatically saves all tasks to browser storage
- ✅ **Task Statistics** - Track total, completed, and remaining tasks
- ✅ **Clear Functions** - Clear completed or all tasks at once
- ✅ **Responsive Design** - Works perfectly on desktop, tablet, and mobile
- ✅ **Beautiful UI** - Modern gradient background and smooth animations

### Advanced Features
- 🔍 **Search Functionality** - Find tasks by keyword
- 📊 **Completion Percentage** - Track your productivity
- 📅 **Date Range Filtering** - Find tasks created within specific dates
- 📥 **Import/Export** - Backup and restore tasks as JSON
- ⌨️ **Keyboard Support** - Press Enter to add tasks
- 🎨 **Real-time Updates** - Instant UI refresh on changes

## 🚀 Usage

### Getting Started

1. **Open the Application**
   ```bash
   # Simply open index.html in a web browser
   open todo-app/index.html
   ```

2. **Add a Task**
   - Type your task in the input field
   - Click "Add Task" or press Enter

3. **Manage Tasks**
   - Check the checkbox to mark tasks as complete
   - Click "Delete" to remove a task
   - Use filter buttons to view specific task types

4. **Clear Tasks**
   - Click "Clear Completed" to remove all done tasks
   - Click "Clear All" to remove all tasks

### Keyboard Shortcuts
| Key | Action |
|-----|--------|
| Enter | Add new task (when input focused) |

## 📂 File Structure

```
todo-app/
├── index.html       # HTML structure
├── styles.css       # Styling and responsive design
├── app.js          # Application logic and local storage
└── README.md       # This file
```

## 💾 Local Storage Details

### Storage Key
- **Key**: `todos_v1`
- **Format**: JSON array
- **Size**: Typically < 1MB for most users

### Data Structure
```json
[
  {
    "id": 1623456789000,
    "text": "Buy groceries",
    "completed": false,
    "createdAt": "2024-01-15T10:30:00.000Z"
  },
  {
    "id": 1623456799000,
    "text": "Finish project",
    "completed": true,
    "createdAt": "2024-01-15T11:00:00.000Z"
  }
]
```

### Browser Compatibility
- ✅ Chrome 4+
- ✅ Firefox 3.5+
- ✅ Safari 4+
- ✅ Edge (all versions)
- ✅ Mobile browsers (iOS Safari, Chrome Mobile, etc.)

## 🎨 Design

### Color Scheme
- **Primary**: `#1E293B` (Slate)
- **Success**: `#10B981` (Emerald)
- **Warning**: `#F59E0B` (Amber)
- **Danger**: `#EF4444` (Red)
- **Background Gradient**: Purple to violet

### Responsive Breakpoints
- **Desktop**: Full layout (600px+)
- **Tablet**: Adjusted spacing (640px)
- **Mobile**: Stacked layout (< 600px)

## 🔧 JavaScript API

The `TodoApp` class provides the following methods:

### Public Methods

```javascript
// CRUD Operations
app.addTodo()                    // Add new todo from input
app.toggleTodo(id)               // Toggle completion status
app.deleteTodo(id)               // Delete a todo
app.clearCompleted()             // Remove all completed todos
app.clearAll()                   // Remove all todos

// Filtering
app.setFilter(filter)            // Set filter: 'all', 'active', 'completed'
app.getFilteredTodos()           // Get todos based on current filter

// Storage
app.saveToStorage()              // Save todos to localStorage
app.loadFromStorage()            // Load todos from localStorage
app.exportTodos()                // Export todos as JSON file
app.importTodos(file)            // Import todos from JSON file

// Utilities
app.getCompletionPercentage()    // Get % of completed tasks
app.getTodosByDateRange(start, end)  // Get todos within date range
app.searchTodos(query)           // Search todos by keyword
```

### Example Usage

```javascript
// Access the global app instance
console.log(app.todos);                    // View all todos
console.log(app.getCompletionPercentage()); // See completion %

// Search for tasks
const results = app.searchTodos('grocery');

// Get todos from last 7 days
const today = new Date();
const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
const recentTodos = app.getTodosByDateRange(weekAgo, today);
```

## 💡 Tips & Tricks

### Browser Console Commands
```javascript
// View all todos
app.todos

// Get stats
app.todos.length                    // Total tasks
app.todos.filter(t => t.completed).length  // Completed tasks

// Export for backup
app.exportTodos()  // Downloads JSON file

// Check storage usage
console.log(localStorage.getItem('todos_v1'))
```

### Data Persistence
- All changes are automatically saved to localStorage
- Data persists even after closing the browser
- Clear browser cache to reset data
- Or use "Clear All" button in the app

## 🚨 Troubleshooting

### Tasks Not Saving
- Check if localStorage is enabled in your browser
- Check browser console for errors (F12)
- Try clearing browser cache
- Ensure you have enough storage space

### Import Not Working
- Ensure JSON file is in correct format
- File should contain an array of todo objects
- Check that each todo has `id`, `text`, `completed`, and `createdAt` fields

### Performance Issues
- App is optimized for 1,000+ tasks
- For very large lists (10,000+), consider archiving old tasks
- Export old data as backup before clearing

## 📦 Installation

### No Installation Required!
Simply open `index.html` in your browser. No dependencies, build tools, or server needed.

### Optional: Run a Local Server
```bash
# Using Python 3
python -m http.server 8000

# Using Node.js (with http-server)
npx http-server

# Using Ruby
ruby -run -ehttpd . -p8000

# Then visit: http://localhost:8000/todo-app/
```

## 🔒 Privacy & Security

- ✅ All data is stored locally on your device
- ✅ No data is sent to any server
- ✅ No tracking or analytics
- ✅ Completely private and offline-capable
- ⚠️ Clearing browser data will delete tasks

## 🐛 Known Issues

- localStorage has ~5-10MB limit per domain
- Private/Incognito mode may not persist data
- Some browsers limit localStorage in certain contexts

## 🎓 Learning Resources

This project demonstrates:
- **DOM Manipulation**: Creating and updating HTML elements
- **Event Handling**: Click, keypress, change events
- **Local Storage API**: Saving/loading data from browser
- **JavaScript OOP**: Class-based architecture
- **CSS Flexbox & Grid**: Modern responsive layouts
- **JSON**: Data serialization and parsing
- **ES6+ Features**: Arrow functions, template literals, destructuring

## 📄 License

Free to use and modify for personal or commercial projects.

## 🤝 Contributing

Feel free to fork and enhance this project with:
- Categories/Tags
- Priority levels
- Due dates and reminders
- Recurring tasks
- Dark mode
- Cloud sync
- Collaborative features

## ✨ Version History

### v1.0.0 (Current)
- Initial release
- Core CRUD operations
- Local storage persistence
- Filter functionality
- Responsive design
- Statistics tracking

---

**Created with ❤️ for productivity lovers**
