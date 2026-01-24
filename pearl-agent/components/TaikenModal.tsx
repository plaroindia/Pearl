import React, { ReactNode } from 'react';

interface TaikenModalProps {
  title: string;
  icon: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  color?: 'amber' | 'red' | 'emerald' | 'indigo' | 'slate';
}

const TaikenModal: React.FC<TaikenModalProps> = ({ title, icon, onClose, children, footer, color = 'indigo' }) => {
  const colorMap = {
    amber: 'text-amber-500 bg-amber-50 dark:bg-amber-900/20',
    red: 'text-red-500 bg-red-50 dark:bg-red-900/20',
    emerald: 'text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20',
    indigo: 'text-indigo-600 bg-indigo-50 dark:bg-indigo-900/20',
    slate: 'text-slate-600 bg-slate-100 dark:bg-slate-900',
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Overlay */}
      <div 
        className="absolute inset-0 bg-slate-900/60 backdrop-blur-sm animate-fade-in"
        onClick={onClose}
      />
      
      {/* Content */}
      <div className="relative w-full max-w-lg bg-white dark:bg-slate-950 rounded-[2.5rem] shadow-2xl overflow-hidden animate-slide-up border border-slate-200 dark:border-slate-800">
        {/* Header */}
        <div className="p-6 border-b border-slate-100 dark:border-slate-900 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-full flex items-center justify-center ${colorMap[color]}`}>
              <span className="material-icons">{icon}</span>
            </div>
            <h3 className="text-xl font-bold">{title}</h3>
          </div>
          <button 
            onClick={onClose}
            className="w-10 h-10 rounded-full bg-slate-50 dark:bg-slate-900 flex items-center justify-center text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <span className="material-icons">close</span>
          </button>
        </div>

        {/* Body */}
        <div className="p-8 max-h-[70vh] overflow-y-auto scrollbar-hide">
          {children}
        </div>

        {/* Footer */}
        {footer && (
          <div className="p-6 bg-slate-50 dark:bg-slate-900/50 flex justify-end">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};

export default TaikenModal;
