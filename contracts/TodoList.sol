// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract TodoList {
    // Enum for task priority
    enum Priority { LOW, MEDIUM, HIGH, URGENT }
    
    // Enum for task status
    enum Status { PENDING, IN_PROGRESS, COMPLETED, CANCELLED }
    
    // Struct to represent a task
    struct Task {
        uint256 id;
        string title;
        string description;
        Priority priority;
        Status status;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 dueDate;
        address owner;
        bool exists;
    }
    
    // State variables
    uint256 public totalTasks;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks;
    mapping(address => uint256) public userTaskCount;
    
    // Task statistics per user
    mapping(address => uint256) public completedTasks;
    mapping(address => uint256) public pendingTasks;
    mapping(address => uint256) public inProgressTasks;
    mapping(address => uint256) public cancelledTasks;
    
    // Events
    event TaskCreated(
        uint256 indexed taskId,
        address indexed owner,
        string title,
        Priority priority,
        uint256 dueDate,
        uint256 timestamp
    );
    
    event TaskUpdated(
        uint256 indexed taskId,
        address indexed owner,
        Status oldStatus,
        Status newStatus,
        uint256 timestamp
    );
    
    event TaskCompleted(
        uint256 indexed taskId,
        address indexed owner,
        uint256 timestamp
    );
    
    event TaskDeleted(
        uint256 indexed taskId,
        address indexed owner,
        uint256 timestamp
    );
    
    // Modifiers
    modifier onlyTaskOwner(uint256 _taskId) {
        require(tasks[_taskId].exists, "Task does not exist");
        require(tasks[_taskId].owner == msg.sender, "Not the task owner");
        _;
    }
    
    modifier validTaskId(uint256 _taskId) {
        require(tasks[_taskId].exists, "Task does not exist");
        _;
    }
    
    // Constructor
    constructor() {
        totalTasks = 0;
    }
    
    // Create a new task
    function createTask(
        string memory _title,
        string memory _description,
        Priority _priority,
        uint256 _dueDate
    ) public returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_title).length <= 100, "Title too long (max 100 chars)");
        require(bytes(_description).length <= 500, "Description too long (max 500 chars)");
        require(_dueDate == 0 || _dueDate > block.timestamp, "Due date must be in the future");
        
        totalTasks++;
        uint256 taskId = totalTasks;
        
        tasks[taskId] = Task({
            id: taskId,
            title: _title,
            description: _description,
            priority: _priority,
            status: Status.PENDING,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            dueDate: _dueDate,
            owner: msg.sender,
            exists: true
        });
        
        userTasks[msg.sender].push(taskId);
        userTaskCount[msg.sender]++;
        pendingTasks[msg.sender]++;
        
        emit TaskCreated(taskId, msg.sender, _title, _priority, _dueDate, block.timestamp);
        
        return taskId;
    }
    
    // Update task status
    function updateTaskStatus(uint256 _taskId, Status _newStatus) 
        public 
        onlyTaskOwner(_taskId) 
    {
        Task storage task = tasks[_taskId];
        Status oldStatus = task.status;
        
        require(oldStatus != _newStatus, "Status is already set to this value");
        
        // Update status counters
        _decrementStatusCounter(msg.sender, oldStatus);
        _incrementStatusCounter(msg.sender, _newStatus);
        
        task.status = _newStatus;
        task.updatedAt = block.timestamp;
        
        emit TaskUpdated(_taskId, msg.sender, oldStatus, _newStatus, block.timestamp);
        
        if (_newStatus == Status.COMPLETED) {
            emit TaskCompleted(_taskId, msg.sender, block.timestamp);
        }
    }
    
    // Mark task as completed
    function completeTask(uint256 _taskId) public onlyTaskOwner(_taskId) {
        updateTaskStatus(_taskId, Status.COMPLETED);
    }
    
    // Mark task as in progress
    function startTask(uint256 _taskId) public onlyTaskOwner(_taskId) {
        updateTaskStatus(_taskId, Status.IN_PROGRESS);
    }
    
    // Cancel a task
    function cancelTask(uint256 _taskId) public onlyTaskOwner(_taskId) {
        updateTaskStatus(_taskId, Status.CANCELLED);
    }
    
    // Update task details
    function updateTask(
        uint256 _taskId,
        string memory _title,
        string memory _description,
        Priority _priority,
        uint256 _dueDate
    ) public onlyTaskOwner(_taskId) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_title).length <= 100, "Title too long (max 100 chars)");
        require(bytes(_description).length <= 500, "Description too long (max 500 chars)");
        require(_dueDate == 0 || _dueDate > block.timestamp, "Due date must be in the future");
        
        Task storage task = tasks[_taskId];
        task.title = _title;
        task.description = _description;
        task.priority = _priority;
        task.dueDate = _dueDate;
        task.updatedAt = block.timestamp;
        
        emit TaskUpdated(_taskId, msg.sender, task.status, task.status, block.timestamp);
    }
    
    // Delete a task
    function deleteTask(uint256 _taskId) public onlyTaskOwner(_taskId) {
        Task storage task = tasks[_taskId];
        
        // Update status counters
        _decrementStatusCounter(msg.sender, task.status);
        userTaskCount[msg.sender]--;
        
        // Remove from user's task list
        uint256[] storage userTaskList = userTasks[msg.sender];
        for (uint256 i = 0; i < userTaskList.length; i++) {
            if (userTaskList[i] == _taskId) {
                userTaskList[i] = userTaskList[userTaskList.length - 1];
                userTaskList.pop();
                break;
            }
        }
        
        emit TaskDeleted(_taskId, msg.sender, block.timestamp);
        
        // Mark as non-existent
        task.exists = false;
    }
    
    // Get task details
    function getTask(uint256 _taskId) 
        public 
        view 
        validTaskId(_taskId) 
        returns (
            uint256 id,
            string memory title,
            string memory description,
            Priority priority,
            Status status,
            uint256 createdAt,
            uint256 updatedAt,
            uint256 dueDate,
            address owner
        ) 
    {
        Task memory task = tasks[_taskId];
        return (
            task.id,
            task.title,
            task.description,
            task.priority,
            task.status,
            task.createdAt,
            task.updatedAt,
            task.dueDate,
            task.owner
        );
    }
    
    // Get user's task IDs
    function getUserTasks(address _user) public view returns (uint256[] memory) {
        return userTasks[_user];
    }
    
    // Get user's tasks by status
    function getUserTasksByStatus(address _user, Status _status) 
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory userTaskList = userTasks[_user];
        uint256[] memory filteredTasks = new uint256[](userTaskList.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < userTaskList.length; i++) {
            if (tasks[userTaskList[i]].exists && tasks[userTaskList[i]].status == _status) {
                filteredTasks[count] = userTaskList[i];
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredTasks[i];
        }
        
        return result;
    }
    
    // Get user's tasks by priority
    function getUserTasksByPriority(address _user, Priority _priority) 
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory userTaskList = userTasks[_user];
        uint256[] memory filteredTasks = new uint256[](userTaskList.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < userTaskList.length; i++) {
            if (tasks[userTaskList[i]].exists && tasks[userTaskList[i]].priority == _priority) {
                filteredTasks[count] = userTaskList[i];
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = filteredTasks[i];
        }
        
        return result;
    }
    
    // Get overdue tasks for a user
    function getOverdueTasks(address _user) public view returns (uint256[] memory) {
        uint256[] memory userTaskList = userTasks[_user];
        uint256[] memory overdueTasks = new uint256[](userTaskList.length);
        uint256 count = 0;
        
        for (uint256 i = 0; i < userTaskList.length; i++) {
            Task memory task = tasks[userTaskList[i]];
            if (task.exists && 
                task.dueDate > 0 && 
                task.dueDate < block.timestamp && 
                task.status != Status.COMPLETED && 
                task.status != Status.CANCELLED) {
                overdueTasks[count] = userTaskList[i];
                count++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = overdueTasks[i];
        }
        
        return result;
    }
    
    // Get user statistics
    function getUserStats(address _user) 
        public 
        view 
        returns (
            uint256 total,
            uint256 completed,
            uint256 pending,
            uint256 inProgress,
            uint256 cancelled,
            uint256 overdue
        ) 
    {
        total = userTaskCount[_user];
        completed = completedTasks[_user];
        pending = pendingTasks[_user];
        inProgress = inProgressTasks[_user];
        cancelled = cancelledTasks[_user];
        overdue = getOverdueTasks(_user).length;
    }
    
    // Get completion rate for user (percentage)
    function getCompletionRate(address _user) public view returns (uint256) {
        uint256 total = userTaskCount[_user];
        if (total == 0) return 0;
        
        uint256 completed = completedTasks[_user];
        return (completed * 100) / total;
    }
    
    // Check if task is overdue
    function isTaskOverdue(uint256 _taskId) public view validTaskId(_taskId) returns (bool) {
        Task memory task = tasks[_taskId];
        return task.dueDate > 0 && 
               task.dueDate < block.timestamp && 
               task.status != Status.COMPLETED && 
               task.status != Status.CANCELLED;
    }
    
    // Get contract statistics
    function getContractStats() 
        public 
        view 
        returns (
            uint256 totalTasksCreated,
            uint256 activeUsers,
            uint256 totalCompletedTasks
        ) 
    {
        totalTasksCreated = totalTasks;
        // activeUsers would need additional tracking in a real implementation
        activeUsers = 0; // Simplified for this example
        
        // Calculate total completed tasks across all users
        totalCompletedTasks = 0;
        // This is simplified - in practice you'd track this more efficiently
    }
    
    // Internal helper functions
    function _incrementStatusCounter(address _user, Status _status) internal {
        if (_status == Status.PENDING) {
            pendingTasks[_user]++;
        } else if (_status == Status.IN_PROGRESS) {
            inProgressTasks[_user]++;
        } else if (_status == Status.COMPLETED) {
            completedTasks[_user]++;
        } else if (_status == Status.CANCELLED) {
            cancelledTasks[_user]++;
        }
    }
    
    function _decrementStatusCounter(address _user, Status _status) internal {
        if (_status == Status.PENDING) {
            pendingTasks[_user]--;
        } else if (_status == Status.IN_PROGRESS) {
            inProgressTasks[_user]--;
        } else if (_status == Status.COMPLETED) {
            completedTasks[_user]--;
        } else if (_status == Status.CANCELLED) {
            cancelledTasks[_user]--;
        }
    }
    
    // Utility function to convert priority enum to string
    function priorityToString(Priority _priority) public pure returns (string memory) {
        if (_priority == Priority.LOW) return "Low";
        if (_priority == Priority.MEDIUM) return "Medium";
        if (_priority == Priority.HIGH) return "High";
        if (_priority == Priority.URGENT) return "Urgent";
        return "Unknown";
    }
    
    // Utility function to convert status enum to string
    function statusToString(Status _status) public pure returns (string memory) {
        if (_status == Status.PENDING) return "Pending";
        if (_status == Status.IN_PROGRESS) return "In Progress";
        if (_status == Status.COMPLETED) return "Completed";
        if (_status == Status.CANCELLED) return "Cancelled";
        return "Unknown";
    }
}
