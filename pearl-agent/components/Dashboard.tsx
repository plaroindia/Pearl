import React, { useState, useEffect } from 'react';
import { authService } from '../src/services/auth.service';
import { apiService } from '../src/services/api.service';

interface DashboardProps {
  onStartJourney?: () => void;
  onNavigate?: (section: string) => void;
}

interface UserStats {
  plaroPoints: number;
  streak: number;
  skillsMastered: number;
  matchScore: number;
}

interface RecentActivity {
  title: string;
  sub: string;
  progress: number;
  date: string;
  type: 'module' | 'taiken' | 'checkpoint';
}

const Dashboard: React.FC<DashboardProps> = ({ onStartJourney, onNavigate }) => {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState<UserStats>({
    plaroPoints: 0,
    streak: 0,
    skillsMastered: 0,
    matchScore: 0
  });
  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [userName, setUserName] = useState('');
  
  const authState = authService.getState();

  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      const user = authState.user;
      
      if (!user) {
        console.error('No authenticated user');
        setLoading(false);
        return;
      }

      setUserName(user.username);

      // Fetch user profile with stats
      const profileData = await apiService.getUserProfile(user.id);
      
      if (profileData?.profile) {
        const profile = profileData.profile;
        
        // Calculate stats
        const skillsCount = profileData.skills?.filter((s: any) => s.confidence_score >= 0.8).length || 0;
        const streakCount = profile.streak_count || 0;
        
        setStats({
          plaroPoints: 0, // Will be calculated from transactions
          streak: streakCount,
          skillsMastered: skillsCount,
          matchScore: skillsCount > 0 ? Math.min(98, 70 + skillsCount * 3) : 0
        });
      }

      // Fetch recent module progress
      if (profileData?.active_sessions && profileData.active_sessions.length > 0) {
        const activities: RecentActivity[] = profileData.active_sessions.map((session: any) => {
          const progress = session.actions_completed && session.total_actions 
            ? Math.round((session.actions_completed / session.total_actions) * 100)
            : 0;
          
          const daysAgo = Math.floor(
            (Date.now() - new Date(session.started_at).getTime()) / (1000 * 60 * 60 * 24)
          );
          
          return {
            title: session.skill || 'Learning Path',
            sub: session.module_name || 'Module in Progress',
            progress,
            date: daysAgo === 0 ? 'Today' : daysAgo === 1 ? 'Yesterday' : `${daysAgo} days ago`,
            type: 'module' as const
          };
        }).slice(0, 3);
        
        setRecentActivity(activities);
      } else {
        // Show placeholder if no activities
        setRecentActivity([
          { title: 'Get Started', sub: 'Begin your learning journey', progress: 0, date: 'Now', type: 'module' }
        ]);
      }

    } catch (error) {
      console.error('Error loading dashboard:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-slate-600 dark:text-slate-400">Loading your dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fadeInUp pt-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      {/* Hero Welcome */}
      <section className="bg-gradient-to-r from-blue-600 to-indigo-700 rounded-3xl p-8 sm:p-12 text-white shadow-2xl relative overflow-hidden">
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 bg-white/20 backdrop-blur-md px-4 py-1 rounded-full text-sm font-medium mb-6">
            <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
            Career Accelerator Active
          </div>
          <h1 className="text-4xl sm:text-6xl font-extrabold mb-4">
            Welcome back, <span className="text-blue-300">{userName}</span>!
          </h1>
          <p className="text-lg sm:text-xl text-blue-100 mb-8 opacity-90">
            Master in-demand skills, track your progress, and connect with opportunities that match your growth. 
            PEARL is your agentic career mentor.
          </p>
          <div className="flex flex-wrap gap-4">
            <button 
              onClick={onStartJourney}
              className="bg-white text-blue-700 px-8 py-4 rounded-xl font-bold hover:bg-blue-50 transition-all flex items-center gap-2 shadow-lg"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"/>
              </svg>
              Start Learning Journey
            </button>
            <button 
              onClick={() => onNavigate?.('jobs')}
              className="bg-blue-500/30 backdrop-blur-md border border-white/30 text-white px-8 py-4 rounded-xl font-bold hover:bg-white/20 transition-all flex items-center gap-2"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
              </svg>
              Explore Jobs
            </button>
          </div>
        </div>
        
        <div className="absolute top-[-50px] right-[-50px] w-64 h-64 bg-white/10 rounded-full blur-3xl"></div>
        <div className="absolute bottom-[-20px] left-[40%] w-32 h-32 bg-blue-400/20 rounded-full blur-2xl"></div>
      </section>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 flex items-center gap-4 hover:shadow-md transition-all">
          <div className="w-12 h-12 bg-yellow-100 rounded-xl flex items-center justify-center text-2xl">
            🏆
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Plaro Points</p>
            <p className="text-2xl font-bold text-yellow-600">{stats.plaroPoints.toLocaleString()}</p>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 flex items-center gap-4 hover:shadow-md transition-all">
          <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-2xl">
            🔥
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Day Streak</p>
            <p className="text-2xl font-bold text-orange-600">{stats.streak} Days</p>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 flex items-center gap-4 hover:shadow-md transition-all">
          <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center text-2xl">
            🎯
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Skills Mastered</p>
            <p className="text-2xl font-bold text-blue-600">{stats.skillsMastered}</p>
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl shadow-sm border border-slate-200 dark:border-slate-800 flex items-center gap-4 hover:shadow-md transition-all">
          <div className="w-12 h-12 bg-indigo-100 rounded-xl flex items-center justify-center text-2xl">
            🚀
          </div>
          <div>
            <p className="text-sm font-medium text-slate-500 dark:text-slate-400">Match Score</p>
            <p className="text-2xl font-bold text-indigo-600">{stats.matchScore}%</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Recent Activity */}
        <div className="lg:col-span-2 space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="text-2xl font-bold">Recent Activity</h2>
            <button 
              onClick={() => onNavigate?.('progress')}
              className="text-blue-600 text-sm font-semibold hover:underline"
            >
              View All
            </button>
          </div>
          
          <div className="space-y-4">
            {recentActivity.length > 0 ? (
              recentActivity.map((activity, i) => (
                <div 
                  key={i} 
                  className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 flex items-center justify-between hover:border-blue-300 transition-all cursor-pointer group"
                >
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 rounded-full bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center text-blue-600 font-bold">
                      {activity.progress === 100 ? '✓' : i + 1}
                    </div>
                    <div>
                      <h3 className="font-bold group-hover:text-blue-600 transition-colors">{activity.title}</h3>
                      <p className="text-sm text-slate-500 dark:text-slate-400">{activity.sub}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <div className="w-32 bg-slate-100 dark:bg-slate-800 h-2 rounded-full mb-1">
                      <div 
                        className="bg-blue-600 h-full rounded-full transition-all duration-500" 
                        style={{ width: `${activity.progress}%` }}
                      ></div>
                    </div>
                    <span className="text-xs text-slate-400 font-medium">{activity.date}</span>
                  </div>
                </div>
              ))
            ) : (
              <div className="bg-white dark:bg-slate-900 p-8 rounded-2xl border border-slate-200 dark:border-slate-800 text-center">
                <p className="text-slate-500">No recent activity. Start learning to see your progress here!</p>
                <button 
                  onClick={onStartJourney}
                  className="mt-4 bg-blue-600 text-white px-6 py-2 rounded-xl font-bold hover:bg-blue-700 transition"
                >
                  Start Learning
                </button>
              </div>
            )}
          </div>
        </div>

        {/* Daily Challenge & Leaderboard */}
        <div className="space-y-6">
          <h2 className="text-2xl font-bold">Daily Challenge</h2>
          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border-2 border-blue-500 shadow-xl relative">
            <div className="absolute top-[-15px] right-4 bg-blue-500 text-white px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider">
              Popular
            </div>
            <div className="text-3xl mb-4">🚀</div>
            <h3 className="text-xl font-bold mb-2">Fast Learner</h3>
            <p className="text-slate-600 dark:text-slate-400 text-sm mb-6">
              Complete 2 modules today to earn double XP and a "Fast Track" badge for your profile.
            </p>
            <div className="space-y-3 mb-6">
              <div className="flex justify-between text-sm mb-1">
                <span className="font-medium">Today's Progress</span>
                <span className="text-blue-600 font-bold">0 / 2</span>
              </div>
              <div className="w-full bg-slate-100 dark:bg-slate-800 h-3 rounded-full">
                <div className="bg-blue-500 h-full rounded-full" style={{ width: '0%' }}></div>
              </div>
            </div>
            <button 
              onClick={onStartJourney}
              className="w-full bg-blue-600 text-white py-3 rounded-xl font-bold hover:bg-blue-700 transition-all"
            >
              Start Challenge
            </button>
          </div>
          
          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800">
            <h3 className="font-bold mb-4 flex items-center gap-2">
              <span className="text-blue-500">🏆</span> Leaderboard
            </h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-2 rounded-lg">
                <div className="flex items-center gap-3">
                  <span className="text-slate-400 text-xs font-bold w-4">#1</span>
                  <img 
                    src="https://api.dicebear.com/7.x/avataaars/svg?seed=1" 
                    className="w-8 h-8 rounded-full border border-slate-200" 
                    alt="" 
                  />
                  <span className="text-sm font-semibold">Sarah Chen</span>
                </div>
                <span className="text-sm font-bold text-blue-600">3,450</span>
              </div>
              
              <div className="flex items-center justify-between p-2 rounded-lg bg-blue-50 dark:bg-blue-900/20 ring-1 ring-blue-200">
                <div className="flex items-center gap-3">
                  <span className="text-slate-400 text-xs font-bold w-4">#4</span>
                  <img 
                    src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${userName}`}
                    className="w-8 h-8 rounded-full border border-slate-200" 
                    alt="" 
                  />
                  <span className="text-sm font-semibold">{userName}</span>
                </div>
                <span className="text-sm font-bold text-blue-600">{stats.plaroPoints}</span>
              </div>
              
              <div className="flex items-center justify-between p-2 rounded-lg">
                <div className="flex items-center gap-3">
                  <span className="text-slate-400 text-xs font-bold w-4">#12</span>
                  <img 
                    src="https://api.dicebear.com/7.x/avataaars/svg?seed=3" 
                    className="w-8 h-8 rounded-full border border-slate-200" 
                    alt="" 
                  />
                  <span className="text-sm font-semibold">David Kim</span>
                </div>
                <span className="text-sm font-bold text-blue-600">980</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;