
export type Section = 'home' | 'roadmap' | 'progress' | 'jobs' | 'profile' | 'onboarding' | 'taiken';

export interface Module {
  id: string;
  title: string;
  description: string;
  estimatedHours: number;
  status: 'completed' | 'active' | 'locked';
  type: 'byte' | 'course' | 'taiken' | 'checkpoint';
  skills: string[];
}

export interface Job {
  id: string;
  title: string;
  company: string;
  location: string;
  matchScore: number;
  salary: string;
  type: string;
  skills: string[];
  url: string;
}

export interface UserStats {
  points: number;
  streak: number;
  masteredSkills: number;
  completedModules: number;
  learningHours: number;
}

// Taiken types
export interface Question {
  id: number;
  question: string;
  code: string;
  options: string[];
  correct: number;
  explanation: string;
}

export interface PracticeSet {
  title: string;
  description: string;
  icon: string;
  color: string;
  questions: Question[];
}

export interface GameState {
  currentEpisode: number;
  currentQuestion: number;
  lives: number;
  score: number;
  answeredQuestions: {
    episode: number;
    question: number;
    selected: number;
    correct: boolean;
  }[];
  episode1Complete: boolean;
  episode2Complete: boolean;
  episode3Complete: boolean;
}

export interface PracticeState {
  activeSetId: string | null;
  currentQuestionIndex: number;
  lives: number;
  score: number;
  hints: number;
  isAnswered: boolean;
  selectedOption: number | null;
}

export type Theme = 'light' | 'dark';
