const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TodoList Contract", function () {
  let TodoList;
  let todoList;
  let owner;
  let user1;
  let user2;

  // Enum values for testing
  const Priority = { LOW: 0, MEDIUM: 1, HIGH: 2, URGENT: 3 };
  const Status = { PENDING: 0, IN_PROGRESS: 1, COMPLETED: 2, CANCELLED: 3 };

  beforeEach(async function () {
    // Get signers
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy TodoList contract
    TodoList = await ethers.getContractFactory("TodoList");
    todoList = await TodoList.deploy();
  });

  describe("Deployment", function () {
    it("Should initialize with zero total tasks", async function () {
      expect(await todoList.totalTasks()).to.equal(0);
    });

    it("Should have empty user task counts", async function () {
      expect(await todoList.userTaskCount(owner.address)).to.equal(0);
      expect(await todoList.completedTasks(owner.address)).to.equal(0);
      expect(await todoList.pendingTasks(owner.address)).to.equal(0);
    });
  });

  describe("Task Creation", function () {
    it("Should create a new task successfully", async function () {
      const title = "Test Task";
      const description = "This is a test task";
      const priority = Priority.HIGH;
      const dueDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now

      await expect(todoList.createTask(title, description, priority, dueDate))
        .to.emit(todoList, "TaskCreated")
        .withArgs(1, owner.address, title, priority, dueDate, await time.latest() + 1);

      expect(await todoList.totalTasks()).to.equal(1);
      expect(await todoList.userTaskCount(owner.address)).to.equal(1);
      expect(await todoList.pendingTasks(owner.address)).to.equal(1);
    });

    it("Should reject empty title", async function () {
      await expect(todoList.createTask("", "Description", Priority.LOW, 0))
        .to.be.revertedWith("Title cannot be empty");
    });

    it("Should reject title that's too long", async function () {
      const longTitle = "a".repeat(101);
      await expect(todoList.createTask(longTitle, "Description", Priority.LOW, 0))
        .to.be.revertedWith("Title too long (max 100 chars)");
    });

    it("Should reject description that's too long", async function () {
      const longDescription = "a".repeat(501);
      await expect(todoList.createTask("Title", longDescription, Priority.LOW, 0))
        .to.be.revertedWith("Description too long (max 500 chars)");
    });

    it("Should reject past due date", async function () {
      const pastDate = Math.floor(Date.now() / 1000) - 86400; // 1 day ago
      await expect(todoList.createTask("Title", "Description", Priority.LOW, pastDate))
        .to.be.revertedWith("Due date must be in the future");
    });

    it("Should allow zero due date (no deadline)", async function () {
      await expect(todoList.createTask("Title", "Description", Priority.LOW, 0))
        .to.not.be.reverted;
    });

    it("Should return correct task ID", async function () {
      const taskId = await todoList.createTask.staticCall("Title", "Description", Priority.LOW, 0);
      expect(taskId).to.equal(1);

      await todoList.createTask("Title", "Description", Priority.LOW, 0);
      const taskId2 = await todoList.createTask.staticCall("Title 2", "Description 2", Priority.HIGH, 0);
      expect(taskId2).to.equal(2);
    });
  });

  describe("Task Retrieval", function () {
    beforeEach(async function () {
      await todoList.createTask("Test Task", "Test Description", Priority.HIGH, 0);
    });

    it("Should retrieve task details correctly", async function () {
      const [id, title, description, priority, status, createdAt, updatedAt, dueDate, taskOwner] = 
        await todoList.getTask(1);

      expect(id).to.equal(1);
      expect(title).to.equal("Test Task");
      expect(description).to.equal("Test Description");
      expect(priority).to.equal(Priority.HIGH);
      expect(status).to.equal(Status.PENDING);
      expect(taskOwner).to.equal(owner.address);
      expect(dueDate).to.equal(0);
    });

    it("Should revert for non-existent task", async function () {
      await expect(todoList.getTask(999))
        .to.be.revertedWith("Task does not exist");
    });

    it("Should return user's task IDs", async function () {
      await todoList.createTask("Task 2", "Description 2", Priority.LOW, 0);
      
      const userTasks = await todoList.getUserTasks(owner.address);
      expect(userTasks.length).to.equal(2);
      expect(userTasks[0]).to.equal(1);
      expect(userTasks[1]).to.equal(2);
    });
  });

  describe("Task Status Updates", function () {
    beforeEach(async function () {
      await todoList.createTask("Test Task", "Test Description", Priority.HIGH, 0);
    });

    it("Should update task status correctly", async function () {
      await expect(todoList.updateTaskStatus(1, Status.IN_PROGRESS))
        .to.emit(todoList, "TaskUpdated")
        .withArgs(1, owner.address, Status.PENDING, Status.IN_PROGRESS, await time.latest() + 1);

      const [, , , , status] = await todoList.getTask(1);
      expect(status).to.equal(Status.IN_PROGRESS);
      
      expect(await todoList.pendingTasks(owner.address)).to.equal(0);
      expect(await todoList.inProgressTasks(owner.address)).to.equal(1);
    });

    it("Should complete task successfully", async function () {
      await expect(todoList.completeTask(1))
        .to.emit(todoList, "TaskCompleted")
        .withArgs(1, owner.address, await time.latest() + 1);

      const [, , , , status] = await todoList.getTask(1);
      expect(status).to.equal(Status.COMPLETED);
      expect(await todoList.completedTasks(owner.address)).to.equal(1);
    });

    it("Should start task successfully", async function () {
      await todoList.startTask(1);
      const [, , , , status] = await todoList.getTask(1);
      expect(status).to.equal(Status.IN_PROGRESS);
    });

    it("Should cancel task successfully", async function () {
      await todoList.cancelTask(1);
      const [, , , , status] = await todoList.getTask(1);
      expect(status).to.equal(Status.CANCELLED);
    });

    it("Should reject status update from non-owner", async function () {
      await expect(todoList.connect(user1).updateTaskStatus(1, Status.COMPLETED))
        .to.be.revertedWith("Not the task owner");
    });

    it("Should reject setting same status", async function () {
      await expect(todoList.updateTaskStatus(1, Status.PENDING))
        .to.be.revertedWith("Status is already set to this value");
    });
  });

  describe("Task Updates", function () {
    beforeEach(async function () {
      await todoList.createTask("Original Title", "Original Description", Priority.LOW, 0);
    });

    it("Should update task details successfully", async function () {
      const newTitle = "Updated Title";
      const newDescription = "Updated Description";
      const newPriority = Priority.URGENT;
      const newDueDate = Math.floor(Date.now() / 1000) + 86400;

      await todoList.updateTask(1, newTitle, newDescription, newPriority, newDueDate);

      const [, title, description, priority, , , , dueDate] = await todoList.getTask(1);
      expect(title).to.equal(newTitle);
      expect(description).to.equal(newDescription);
      expect(priority).to.equal(newPriority);
      expect(dueDate).to.equal(newDueDate);
    });

    it("Should reject update from non-owner", async function () {
      await expect(todoList.connect(user1).updateTask(1, "New Title", "New Desc", Priority.HIGH, 0))
        .to.be.revertedWith("Not the task owner");
    });

    it("Should reject empty title in update", async function () {
      await expect(todoList.updateTask(1, "", "Description", Priority.LOW, 0))
        .to.be.revertedWith("Title cannot be empty");
    });
  });

  describe("Task Deletion", function () {
    beforeEach(async function () {
      await todoList.createTask("Task to Delete", "Description", Priority.LOW, 0);
    });

    it("Should delete task successfully", async function () {
      await expect(todoList.deleteTask(1))
        .to.emit(todoList, "TaskDeleted")
        .withArgs(1, owner.address, await time.latest() + 1);

      expect(await todoList.userTaskCount(owner.address)).to.equal(0);
      expect(await todoList.pendingTasks(owner.address)).to.equal(0);

      // Task should not exist anymore
      await expect(todoList.getTask(1))
        .to.be.revertedWith("Task does not exist");
    });

    it("Should reject deletion from non-owner", async function () {
      await expect(todoList.connect(user1).deleteTask(1))
        .to.be.revertedWith("Not the task owner");
    });

    it("Should remove task from user's task list", async function () {
      await todoList.createTask("Task 2", "Description 2", Priority.LOW, 0);
      
      let userTasks = await todoList.getUserTasks(owner.address);
      expect(userTasks.length).to.equal(2);

      await todoList.deleteTask(1);
      
      userTasks = await todoList.getUserTasks(owner.address);
      expect(userTasks.length).to.equal(1);
      expect(userTasks[0]).to.equal(2);
    });
  });

  describe("Task Filtering", function () {
    beforeEach(async function () {
      await todoList.createTask("Pending Task", "Description", Priority.LOW, 0);
      await todoList.createTask("High Priority Task", "Description", Priority.HIGH, 0);
      await todoList.createTask("Medium Priority Task", "Description", Priority.MEDIUM, 0);
      
      await todoList.completeTask(2);
      await todoList.startTask(3);
    });

    it("Should filter tasks by status", async function () {
      const pendingTasks = await todoList.getUserTasksByStatus(owner.address, Status.PENDING);
      expect(pendingTasks.length).to.equal(1);
      expect(pendingTasks[0]).to.equal(1);

      const completedTasks = await todoList.getUserTasksByStatus(owner.address, Status.COMPLETED);
      expect(completedTasks.length).to.equal(1);
      expect(completedTasks[0]).to.equal(2);

      const inProgressTasks = await todoList.getUserTasksByStatus(owner.address, Status.IN_PROGRESS);
      expect(inProgressTasks.length).to.equal(1);
      expect(inProgressTasks[0]).to.equal(3);
    });

    it("Should filter tasks by priority", async function () {
      const highPriorityTasks = await todoList.getUserTasksByPriority(owner.address, Priority.HIGH);
      expect(highPriorityTasks.length).to.equal(1);
      expect(highPriorityTasks[0]).to.equal(2);

      const lowPriorityTasks = await todoList.getUserTasksByPriority(owner.address, Priority.LOW);
      expect(lowPriorityTasks.length).to.equal(1);
      expect(lowPriorityTasks[0]).to.equal(1);
    });
  });

  describe("Overdue Tasks", function () {
    it("Should identify overdue tasks", async function () {
      const pastDate = Math.floor(Date.now() / 1000) - 86400; // 1 day ago
      const futureDate = Math.floor(Date.now() / 1000) + 86400; // 1 day from now

      // Create tasks with different due dates
      await todoList.createTask("Overdue Task", "Description", Priority.HIGH, pastDate);
      await todoList.createTask("Future Task", "Description", Priority.LOW, futureDate);
      await todoList.createTask("No Due Date", "Description", Priority.MEDIUM, 0);

      const overdueTasks = await todoList.getOverdueTasks(owner.address);
      expect(overdueTasks.length).to.equal(1);
      expect(overdueTasks[0]).to.equal(1);

      expect(await todoList.isTaskOverdue(1)).to.be.true;
      expect(await todoList.isTaskOverdue(2)).to.be.false;
      expect(await todoList.isTaskOverdue(3)).to.be.false;
    });

    it("Should not consider completed tasks as overdue", async function () {
      const pastDate = Math.floor(Date.now() / 1000) - 86400;
      await todoList.createTask("Overdue but Completed", "Description", Priority.HIGH, pastDate);
      await todoList.completeTask(1);

      const overdueTasks = await todoList.getOverdueTasks(owner.address);
      expect(overdueTasks.length).to.equal(0);
      expect(await todoList.isTaskOverdue(1)).to.be.false;
    });
  });

  describe("User Statistics", function () {
    beforeEach(async function () {
      await todoList.createTask("Task 1", "Description", Priority.LOW, 0);
      await todoList.createTask("Task 2", "Description", Priority.HIGH, 0);
      await todoList.createTask("Task 3", "Description", Priority.MEDIUM, 0);
      
      await todoList.completeTask(1);
      await todoList.startTask(2);
      await todoList.cancelTask(3);
    });

    it("Should return correct user statistics", async function () {
      const [total, completed, pending, inProgress, cancelled, overdue] = 
        await todoList.getUserStats(owner.address);

      expect(total).to.equal(3);
      expect(completed).to.equal(1);
      expect(pending).to.equal(0);
      expect(inProgress).to.equal(1);
      expect(cancelled).to.equal(1);
      expect(overdue).to.equal(0);
    });

    it("Should calculate completion rate correctly", async function () {
      const completionRate = await todoList.getCompletionRate(owner.address);
      expect(completionRate).to.equal(33); // 1 out of 3 tasks completed = 33%
    });

    it("Should return 0% completion rate for users with no tasks", async function () {
      const completionRate = await todoList.getCompletionRate(user1.address);
      expect(completionRate).to.equal(0);
    });
  });

  describe("Utility Functions", function () {
    it("Should convert priority enum to string", async function () {
      expect(await todoList.priorityToString(Priority.LOW)).to.equal("Low");
      expect(await todoList.priorityToString(Priority.MEDIUM)).to.equal("Medium");
      expect(await todoList.priorityToString(Priority.HIGH)).to.equal("High");
      expect(await todoList.priorityToString(Priority.URGENT)).to.equal("Urgent");
    });

    it("Should convert status enum to string", async function () {
      expect(await todoList.statusToString(Status.PENDING)).to.equal("Pending");
      expect(await todoList.statusToString(Status.IN_PROGRESS)).to.equal("In Progress");
      expect(await todoList.statusToString(Status.COMPLETED)).to.equal("Completed");
      expect(await todoList.statusToString(Status.CANCELLED)).to.equal("Cancelled");
    });
  });

  describe("Multiple Users", function () {
    it("Should handle multiple users independently", async function () {
      await todoList.connect(user1).createTask("User1 Task", "Description", Priority.HIGH, 0);
      await todoList.connect(user2).createTask("User2 Task", "Description", Priority.LOW, 0);

      expect(await todoList.userTaskCount(user1.address)).to.equal(1);
      expect(await todoList.userTaskCount(user2.address)).to.equal(1);
      expect(await todoList.totalTasks()).to.equal(2);

      const user1Tasks = await todoList.getUserTasks(user1.address);
      const user2Tasks = await todoList.getUserTasks(user2.address);

      expect(user1Tasks.length).to.equal(1);
      expect(user2Tasks.length).to.equal(1);
      expect(user1Tasks[0]).to.not.equal(user2Tasks[0]);
    });

    it("Should prevent cross-user task access", async function () {
      await todoList.connect(user1).createTask("User1 Task", "Description", Priority.HIGH, 0);
      
      await expect(todoList.connect(user2).completeTask(1))
        .to.be.revertedWith("Not the task owner");
      
      await expect(todoList.connect(user2).deleteTask(1))
        .to.be.revertedWith("Not the task owner");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle task creation with maximum length strings", async function () {
      const maxTitle = "a".repeat(100);
      const maxDescription = "b".repeat(500);

      await expect(todoList.createTask(maxTitle, maxDescription, Priority.LOW, 0))
        .to.not.be.reverted;

      const [, title, description] = await todoList.getTask(1);
      expect(title).to.equal(maxTitle);
      expect(description).to.equal(maxDescription);
    });

    it("Should handle empty task lists", async function () {
      const userTasks = await todoList.getUserTasks(user1.address);
      expect(userTasks.length).to.equal(0);

      const pendingTasks = await todoList.getUserTasksByStatus(user1.address, Status.PENDING);
      expect(pendingTasks.length).to.equal(0);
    });
  });
});

// Helper to get latest block timestamp
const time = {
  latest: async () => {
    const block = await ethers.provider.getBlock("latest");
    return block.timestamp;
  }
};
