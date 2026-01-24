/**
 * Learning Service - Manages learning paths, modules, and progress
 * Interfaces with API service for career goals, modules, and checkpoints
 */

import { apiService, CareerGoalResponse, Module, CheckpointResult } from './api.service';

export interface LearningState {
  careerGoal: string | null;
  sessionId: string | null;
  skillsIdentified: Array<{ name: string; confidence: number }>;
  currentSkill: string | null;
  modules: Record<string, Module[]>;
  currentModule: Module | null;
  progress: Record<string, number>; // skill -> completion %
  isLoading: boolean;
  error: string | null;
}

class LearningService {
  private listeners: ((state: LearningState) => void)[] = [];
  private state: LearningState = {
    careerGoal: null,
    sessionId: null,
    skillsIdentified: [],
    currentSkill: null,
    modules: {},
    currentModule: null,
    progress: {},
    isLoading: false,
    error: null,
  };

  constructor() {
    this.loadFromStorage();
  }

  // ==================== Public Methods ====================

  async startCareerJourney(goal: string, jobDescription?: string): Promise<boolean> {
    try {
      this.setState({ isLoading: true, error: null });

      const response = await apiService.parseCareerGoal(goal, jobDescription);

      if (!response.success) {
        throw new Error('Failed to parse career goal');
      }

      this.setState({
        careerGoal: goal,
        sessionId: response.session_id,
        skillsIdentified: response.skills_identified || [],
        isLoading: false,
        error: null,
      });

      this.saveToStorage();
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to start career journey';
      this.setState({
        isLoading: false,
        error: message,
      });
      return false;
    }
  }

  async loadModulesForSkill(skill: string, difficulty?: string): Promise<boolean> {
    try {
      this.setState({ isLoading: true, error: null });

      const modules = await apiService.getModules(skill, difficulty);

      this.setState({
        currentSkill: skill,
        modules: {
          ...this.state.modules,
          [skill]: modules,
        },
        currentModule: modules?.[0] || null,
        isLoading: false,
        error: null,
      });

      this.saveToStorage();
      return true;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to load modules';
      this.setState({
        isLoading: false,
        error: message,
      });
      return false;
    }
  }

  async submitModuleAction(
    moduleId: number,
    actionIndex: number,
    completionData: Record<string, any>
  ): Promise<boolean> {
    const { sessionId, currentSkill } = this.state;

    if (!sessionId || !currentSkill) {
      this.setState({
        error: 'No active session or skill selected',
      });
      return false;
    }

    try {
      this.setState({ isLoading: true, error: null });

      const response = await apiService.submitModuleAction(
        sessionId,
        currentSkill,
        moduleId,
        actionIndex,
        completionData
      );

      if (response.success) {
        this.updateModuleProgress(currentSkill, response.progress || 0);
      }

      this.setState({
        isLoading: false,
        error: null,
      });

      this.saveToStorage();
      return response.success;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to submit action';
      this.setState({
        isLoading: false,
        error: message,
      });
      return false;
    }
  }

  async submitCheckpoint(moduleId: number, answers: number[]): Promise<CheckpointResult | null> {
    const { sessionId, currentSkill } = this.state;

    if (!sessionId || !currentSkill) {
      this.setState({
        error: 'No active session or skill selected',
      });
      return null;
    }

    try {
      this.setState({ isLoading: true, error: null });

      const result = await apiService.submitCheckpoint(
        sessionId,
        currentSkill,
        moduleId,
        answers
      );

      if (result.success) {
        // Update progress based on checkpoint result
        const newProgress = Math.max(
          this.state.progress[currentSkill] || 0,
          (result.correct_answers / result.total_questions) * 100
        );
        this.updateModuleProgress(currentSkill, newProgress);
      }

      this.setState({
        isLoading: false,
        error: null,
      });

      this.saveToStorage();
      return result;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to submit checkpoint';
      this.setState({
        isLoading: false,
        error: message,
      });
      return null;
    }
  }

  selectSkill(skill: string): void {
    this.setState({
      currentSkill: skill,
      currentModule: this.state.modules[skill]?.[0] || null,
    });
    this.saveToStorage();
  }

  selectModule(module: Module): void {
    this.setState({
      currentModule: module,
    });
    this.saveToStorage();
  }

  // ==================== State Management ====================

  getState(): LearningState {
    return { ...this.state };
  }

  getSkillProgress(skill: string): number {
    return this.state.progress[skill] || 0;
  }

  getCompletedSkills(): string[] {
    return Object.entries(this.state.progress)
      .filter(([, progress]) => progress === 100)
      .map(([skill]) => skill);
  }

  subscribe(listener: (state: LearningState) => void): () => void {
    this.listeners.push(listener);

    return () => {
      this.listeners = this.listeners.filter((l) => l !== listener);
    };
  }

  private setState(updates: Partial<LearningState>): void {
    this.state = { ...this.state, ...updates };
    this.listeners.forEach((listener) => listener(this.getState()));
  }

  private updateModuleProgress(skill: string, progress: number): void {
    this.setState({
      progress: {
        ...this.state.progress,
        [skill]: Math.min(100, progress),
      },
    });
  }

  // ==================== Storage ====================

  private saveToStorage(): void {
    try {
      localStorage.setItem('pearl_learning_state', JSON.stringify(this.state));
    } catch (error) {
      console.warn('Failed to save learning state', error);
    }
  }

  private loadFromStorage(): void {
    try {
      const stored = localStorage.getItem('pearl_learning_state');
      if (stored) {
        const parsed = JSON.parse(stored);
        this.state = { ...this.state, ...parsed };
      }
    } catch (error) {
      console.warn('Failed to load learning state', error);
    }
  }

  clearSession(): void {
    this.setState({
      careerGoal: null,
      sessionId: null,
      skillsIdentified: [],
      currentSkill: null,
      modules: {},
      currentModule: null,
      progress: {},
      error: null,
    });
    localStorage.removeItem('pearl_learning_state');
  }
}

// Export singleton instance
export const learningService = new LearningService();
export default learningService;
