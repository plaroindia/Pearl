import React, { useState, useEffect } from 'react';
import { GameState, PracticeState, Theme, Module } from '../types';
import { STORY_QUESTIONS, PRACTICE_SETS } from '../constants';
import StoryView from './StoryView';
import PracticeSession from './PracticeSession';
import TaikenSidebar from './TaikenSidebar';
import TaikenModal from './TaikenModal';

interface TaikenStoryProps {
  onExit: () => void;
  module?: Module;
}

const DEFAULT_GAME_STATE: GameState = {
  currentEpisode: 1,
  currentQuestion: 1,
  lives: 3,
  score: 0,
  answeredQuestions: [],
  episode1Complete: false,
  episode2Complete: false,
  episode3Complete: false,
};

const DEFAULT_PRACTICE_STATE: PracticeState = {
  activeSetId: null,
  currentQuestionIndex: 0,
  lives: 3,
  score: 0,
  hints: 3,
  isAnswered: false,
  selectedOption: null,
};

const TaikenStory: React.FC<TaikenStoryProps> = ({ onExit, module }) => {
  const [gameState, setGameState] = useState<GameState>(() => {
    try {
      const saved = localStorage.getItem('taikenGameState');
      if (saved && saved !== 'undefined' && saved !== 'null') {
        return JSON.parse(saved);
      }
    } catch (e) {
      console.error("Failed to parse game state", e);
    }
    return DEFAULT_GAME_STATE;
  });

  const [practiceState, setPracticeState] = useState<PracticeState>(DEFAULT_PRACTICE_STATE);
  const [theme, setTheme] = useState<Theme>(() => {
    try {
      const saved = localStorage.getItem('taikenTheme');
      return (saved === 'dark' || saved === 'light') ? saved : 'light';
    } catch {
      return 'light';
    }
  });
  const [activeModal, setActiveModal] = useState<'hint' | 'wrong' | 'correct' | 'practiceSets' | 'gameOver' | null>(null);
  const [toast, setToast] = useState<{ message: string; type: string } | null>(null);

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('taikenTheme', theme);
  }, [theme]);

  useEffect(() => {
    try {
      localStorage.setItem('taikenGameState', JSON.stringify(gameState));
    } catch (e) {
      console.warn('Failed to save game state', e);
    }
  }, [gameState]);

  const showToast = (message: string, type: string = 'info') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 3000);
  };

  const toggleTheme = () => {
    setTheme(prev => prev === 'light' ? 'dark' : 'light');
  };

  const handleStorySubmit = (selected: number) => {
    const currentQuestion = STORY_QUESTIONS[`episode${gameState.currentEpisode}`][gameState.currentQuestion - 1];
    const isCorrect = selected === currentQuestion.correct;

    if (isCorrect) {
      setGameState(prev => ({
        ...prev,
        score: prev.score + 100,
        answeredQuestions: [...prev.answeredQuestions, {
          episode: prev.currentEpisode,
          question: prev.currentQuestion,
          selected,
          correct: true
        }]
      }));
      setActiveModal('correct');
    } else {
      setGameState(prev => {
        const nextLives = prev.lives - 1;
        if (nextLives <= 0) {
          setTimeout(() => setActiveModal('gameOver'), 1000);
        }
        return {
          ...prev,
          lives: nextLives,
          answeredQuestions: [...prev.answeredQuestions, {
            episode: prev.currentEpisode,
            question: prev.currentQuestion,
            selected,
            correct: false
          }]
        };
      });
      setActiveModal('wrong');
    }
  };

  const handleHintClick = () => {
    const currentQuestion = STORY_QUESTIONS[`episode${gameState.currentEpisode}`][gameState.currentQuestion - 1];
    showToast(`Hint: ${currentQuestion.explanation.split('.')[0]}`, 'warning');
  };

  const nextQuestion = () => {
    setActiveModal(null);
    if (gameState.currentQuestion < 3) {
      setGameState(prev => ({ ...prev, currentQuestion: prev.currentQuestion + 1 }));
    } else {
      nextEpisode();
    }
  };

  const nextEpisode = () => {
    if (gameState.currentEpisode < 3) {
      setGameState(prev => ({
        ...prev,
        currentEpisode: prev.currentEpisode + 1,
        currentQuestion: 1,
        [`episode${prev.currentEpisode}Complete`]: true
      }));
      showToast(`Episode ${gameState.currentEpisode + 1} Unlocked!`, 'success');
    } else {
      showToast('You have completed all story episodes!', 'success');
    }
  };

  const handleEpisodeClick = (ep: number) => {
    if (gameState.currentEpisode >= ep) {
      setGameState(prev => ({ ...prev, currentEpisode: ep, currentQuestion: 1 }));
    }
  };

  const handlePracticeClick = () => {
    setActiveModal('practiceSets');
  };

  const startPractice = (setId: string) => {
    setPracticeState({
      ...DEFAULT_PRACTICE_STATE,
      activeSetId: setId,
    });
    setActiveModal(null);
  };

  const closePractice = () => {
    setPracticeState(DEFAULT_PRACTICE_STATE);
  };

  const resetGame = () => {
    localStorage.removeItem('taikenGameState');
    setGameState(DEFAULT_GAME_STATE);
    setActiveModal(null);
    showToast('Game Reset!', 'info');
  };

  const currentQuestion = STORY_QUESTIONS[`episode${gameState.currentEpisode}`]?.[gameState.currentQuestion - 1];
  const totalQuestions = 9;
  const progressPercent = Math.min(100, (gameState.answeredQuestions.filter(q => q.correct).length / totalQuestions) * 100);

  if (practiceState.activeSetId) {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-900 p-4">
        <PracticeSession 
          practiceState={practiceState}
          onClose={closePractice}
          setPracticeState={setPracticeState}
          showToast={showToast}
        />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900 flex">
      <TaikenSidebar
        gameState={gameState}
        theme={theme}
        onToggleTheme={toggleTheme}
        onPracticeClick={handlePracticeClick}
        onEpisodeClick={handleEpisodeClick}
      />

      <main className="flex-1 p-6 lg:p-12 overflow-y-auto">
        {/* Header */}
        <div className="mb-8">
          {module && (
            <div className="mb-4">
              <h1 className="text-3xl font-extrabold text-slate-900 dark:text-white mb-2">
                {module.title}
              </h1>
              <p className="text-slate-500 dark:text-slate-400">{module.description}</p>
            </div>
          )}
        </div>

        {/* Main Content */}
        <div className="max-w-4xl mx-auto space-y-8">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <span className="px-2 py-0.5 bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 text-[10px] font-bold uppercase rounded">
                  Episode {gameState.currentEpisode}
                </span>
              </div>
              <h2 className="text-3xl font-extrabold text-slate-900 dark:text-white">
                {gameState.currentEpisode === 1 ? 'The First Bug' : 
                 gameState.currentEpisode === 2 ? 'API Challenges' : 'Final Debug'}
              </h2>
            </div>
            <div className="flex items-center gap-4">
              <div className="text-right">
                <p className="text-xs font-bold text-slate-400 uppercase">Current Score</p>
                <p className="text-xl font-black text-indigo-600">{gameState.score}</p>
              </div>
              <div className="w-12 h-12 bg-indigo-600 rounded-full flex items-center justify-center text-white shadow-xl shadow-indigo-600/20">
                <span className="material-icons">stars</span>
              </div>
            </div>
          </div>

          <StoryView 
            gameState={gameState}
            onStorySubmit={handleStorySubmit}
            onHintClick={handleHintClick}
          />

          <div className="p-6 bg-white dark:bg-slate-950 border border-slate-200 dark:border-slate-800 rounded-2xl flex flex-col md:flex-row items-center justify-between gap-4">
            <div className="flex items-center gap-3 text-slate-500 text-sm italic">
              <span className="material-icons text-indigo-600">info</span>
              Solve all challenges to progress to the next episode
            </div>
            <button 
              onClick={onExit}
              className="px-6 py-2 border-2 border-slate-200 dark:border-slate-800 rounded-full text-sm font-bold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
            >
              Back to Roadmap
            </button>
          </div>
        </div>
      </main>

      {/* Modals */}
      {activeModal === 'correct' && (
        <TaikenModal
          title="Correct Answer!"
          icon="check_circle"
          color="emerald"
          onClose={() => setActiveModal(null)}
          footer={
            <button
              onClick={nextQuestion}
              className="px-6 py-2 bg-emerald-600 text-white rounded-full font-bold hover:bg-emerald-700 transition"
            >
              Continue
            </button>
          }
        >
          <p className="text-slate-600 dark:text-slate-400">
            Great job! You earned 100 points. {currentQuestion?.explanation}
          </p>
        </TaikenModal>
      )}

      {activeModal === 'wrong' && (
        <TaikenModal
          title="Incorrect Answer"
          icon="cancel"
          color="red"
          onClose={() => setActiveModal(null)}
          footer={
            <button
              onClick={nextQuestion}
              className="px-6 py-2 bg-red-600 text-white rounded-full font-bold hover:bg-red-700 transition"
            >
              Continue
            </button>
          }
        >
          <p className="text-slate-600 dark:text-slate-400">
            {currentQuestion?.explanation}
          </p>
        </TaikenModal>
      )}

      {activeModal === 'gameOver' && (
        <TaikenModal
          title="Game Over"
          icon="sentiment_very_dissatisfied"
          color="red"
          onClose={() => setActiveModal(null)}
          footer={
            <div className="flex gap-3">
              <button
                onClick={resetGame}
                className="px-6 py-2 bg-slate-600 text-white rounded-full font-bold hover:bg-slate-700 transition"
              >
                Reset Game
              </button>
              <button
                onClick={onExit}
                className="px-6 py-2 bg-indigo-600 text-white rounded-full font-bold hover:bg-indigo-700 transition"
              >
                Back to Roadmap
              </button>
            </div>
          }
        >
          <p className="text-slate-600 dark:text-slate-400">
            You've run out of lives! Review the material and try again.
          </p>
        </TaikenModal>
      )}

      {activeModal === 'practiceSets' && (
        <TaikenModal
          title="Practice Sets"
          icon="fitness_center"
          color="indigo"
          onClose={() => setActiveModal(null)}
        >
          <div className="space-y-3">
            {Object.entries(PRACTICE_SETS).map(([id, set]) => (
              <button
                key={id}
                onClick={() => startPractice(id)}
                className="w-full p-4 bg-slate-100 dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-indigo-50 dark:hover:bg-indigo-900/20 transition text-left"
              >
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-lg flex items-center justify-center" style={{ backgroundColor: set.color + '20' }}>
                    <span className="material-icons" style={{ color: set.color }}>{set.icon}</span>
                  </div>
                  <div className="flex-1">
                    <h4 className="font-bold text-slate-900 dark:text-white">{set.title}</h4>
                    <p className="text-sm text-slate-500">{set.description}</p>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </TaikenModal>
      )}

      {/* Toast */}
      {toast && (
        <div className={`fixed bottom-8 right-8 px-6 py-4 rounded-2xl shadow-xl z-50 animate-slide-up ${
          toast.type === 'success' ? 'bg-emerald-500 text-white' :
          toast.type === 'error' ? 'bg-red-500 text-white' :
          toast.type === 'warning' ? 'bg-amber-500 text-white' :
          'bg-indigo-600 text-white'
        }`}>
          <p className="font-bold">{toast.message}</p>
        </div>
      )}
    </div>
  );
};

export default TaikenStory;
