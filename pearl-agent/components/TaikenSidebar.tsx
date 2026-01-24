import React from 'react';
import { GameState, Theme } from '../types';

interface TaikenSidebarProps {
  gameState: GameState;
  theme: Theme;
  onToggleTheme: () => void;
  onPracticeClick: () => void;
  onEpisodeClick: (ep: number) => void;
}

const TaikenSidebar: React.FC<TaikenSidebarProps> = ({ gameState, theme, onToggleTheme, onPracticeClick, onEpisodeClick }) => {
  const episodes = [
    { n: 1, title: 'The First Bug', subtitle: 'Debugging basics' },
    { n: 2, title: 'API Challenges', subtitle: 'Master async/await' },
    { n: 3, title: 'Final Debug', subtitle: 'Production readiness' },
  ];

  const totalQuestions = 9;
  const progressPercent = Math.min(100, (gameState.answeredQuestions.filter(q => q.correct).length / totalQuestions) * 100);

  return (
    <aside className="hidden lg:flex w-80 flex-col gap-8 bg-white dark:bg-slate-950 border-r border-slate-200 dark:border-slate-800 p-6 sticky top-0 h-screen overflow-y-auto scrollbar-hide">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="bg-indigo-600 p-1.5 rounded-lg">
            <span className="material-icons text-white text-xl">layers</span>
          </div>
          <span className="font-bold text-xl text-slate-900 dark:text-white">Taiken</span>
        </div>
        <button 
          onClick={onToggleTheme}
          className="p-2 bg-slate-100 dark:bg-slate-900 rounded-full hover:bg-indigo-100 dark:hover:bg-indigo-900/30 transition-colors text-slate-700 dark:text-slate-300"
        >
          <span className="material-icons text-xl">{theme === 'dark' ? 'light_mode' : 'dark_mode'}</span>
        </button>
      </div>

      {/* Progress */}
      <div>
        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">Story Progress</h3>
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-1.5">
            {[1, 2, 3].map(i => (
              <React.Fragment key={i}>
                <div 
                  className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-bold transition-all ${
                    gameState.currentEpisode > i ? 'bg-emerald-500 text-white' : 
                    gameState.currentEpisode === i ? 'bg-indigo-600 text-white ring-4 ring-indigo-500/20' : 
                    'bg-slate-200 dark:bg-slate-800 text-slate-400'
                  }`}
                >
                  {gameState.currentEpisode > i ? <span className="material-icons text-xs">check</span> : i}
                </div>
                {i < 3 && <div className={`h-0.5 w-4 ${gameState.currentEpisode > i ? 'bg-emerald-500' : 'bg-slate-200 dark:bg-slate-800'}`} />}
              </React.Fragment>
            ))}
          </div>
          <span className="text-xs font-bold text-indigo-600">{Math.round(progressPercent)}%</span>
        </div>
        <div className="h-1.5 bg-slate-100 dark:bg-slate-900 rounded-full overflow-hidden">
          <div className="h-full bg-indigo-600 transition-all duration-1000" style={{width: `${progressPercent}%`}} />
        </div>
      </div>

      {/* Lives */}
      <div>
        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">Lives Remaining</h3>
        <div className="flex gap-2">
          {[...Array(3)].map((_, i) => (
            <div 
              key={i} 
              className={`w-10 h-10 rounded-xl flex items-center justify-center transition-all ${
                i < gameState.lives ? 'bg-red-500 shadow-lg shadow-red-500/20 text-white scale-100' : 'bg-slate-200 dark:bg-slate-800 text-slate-400 opacity-50 scale-90'
              }`}
            >
              <span className="material-icons">{i < gameState.lives ? 'favorite' : 'favorite_border'}</span>
            </div>
          ))}
        </div>
        <p className="mt-2 text-xs text-slate-500">{gameState.lives}/3 lives available</p>
      </div>

      {/* Episode List */}
      <div>
        <h3 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">Episodes</h3>
        <div className="space-y-3">
          {episodes.map(ep => {
            const isCompleted = gameState.currentEpisode > ep.n;
            const isActive = gameState.currentEpisode === ep.n;
            const isLocked = gameState.currentEpisode < ep.n;
            
            return (
              <button
                key={ep.n}
                onClick={() => onEpisodeClick(ep.n)}
                disabled={isLocked}
                className={`w-full flex items-center gap-4 p-3 rounded-xl border transition-all text-left ${
                  isActive ? 'bg-indigo-50 dark:bg-indigo-900/20 border-indigo-200 dark:border-indigo-800 ring-2 ring-indigo-500/10' :
                  isCompleted ? 'bg-emerald-50 dark:bg-emerald-900/10 border-emerald-200 dark:border-emerald-900 opacity-80' :
                  'bg-white dark:bg-slate-950 border-slate-200 dark:border-slate-800 opacity-50 cursor-not-allowed'
                }`}
              >
                <div className={`w-10 h-10 rounded-lg flex items-center justify-center font-bold ${
                  isActive ? 'bg-indigo-600 text-white' : 
                  isCompleted ? 'bg-emerald-500 text-white' : 
                  'bg-slate-200 dark:bg-slate-800 text-slate-400'
                }`}>
                  {ep.n}
                </div>
                <div className="flex-1">
                  <h4 className="text-sm font-bold">{ep.title}</h4>
                  <p className="text-[10px] text-slate-500">{ep.subtitle}</p>
                </div>
                <span className="material-icons text-sm opacity-60">
                  {isCompleted ? 'check_circle' : isActive ? 'play_arrow' : 'lock'}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Stats Card */}
      <div className="mt-auto pt-6 border-t border-slate-200 dark:border-slate-800">
        <button 
          onClick={onPracticeClick}
          className="w-full bg-indigo-600 hover:bg-indigo-700 text-white py-3 rounded-xl font-bold transition flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/20"
        >
          <span className="material-icons text-sm">fitness_center</span>
          Practice Sets
        </button>
      </div>
    </aside>
  );
};

export default TaikenSidebar;
