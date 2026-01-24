import React, { useState, useEffect } from 'react';
import { authService } from '../src/services/auth.service';
import { apiService } from '../src/services/api.service';

interface Job {
  id: string;
  title: string;
  company: string;
  location: string;
  matchScore: number;
  salary: string;
  type: string;
  skills: string[];
  url: string;
  matched_skills?: string[];
  missing_skills?: string[];
  match_reason?: string;
}

const Jobs: React.FC = () => {
  const [filter, setFilter] = useState('All');
  const [loading, setLoading] = useState(true);
  const [jobs, setJobs] = useState<Job[]>([]);
  const [userSkills, setUserSkills] = useState<string[]>([]);

  const authState = authService.getState();

  useEffect(() => {
    loadJobs();
  }, []);

  const loadJobs = async () => {
    try {
      setLoading(true);
      const user = authState.user;
      
      if (!user) {
        console.error('No authenticated user');
        setLoading(false);
        return;
      }

      // First get user's skills
      const profileData = await apiService.getUserProfile(user.id);
      
      if (profileData?.skills) {
        const skills = profileData.skills
          .filter((s: any) => s.confidence_score >= 0.5)
          .map((s: any) => s.skill_name);
        
        setUserSkills(skills);

        // Get job recommendations based on skills
        if (skills.length > 0) {
          try {
            const jobMatches = await apiService.getJobRecommendations(
              skills,
              profileData.profile?.location || 'Remote'
            );

            // Transform job matches to Job interface
            const transformedJobs: Job[] = jobMatches.map((match: any) => ({
              id: match.job.id,
              title: match.job.title,
              company: match.job.company,
              location: match.job.location,
              matchScore: Math.round(match.match_percentage),
              salary: match.job.salary_min && match.job.salary_max 
                ? `$${Math.round(match.job.salary_min / 1000)}k - $${Math.round(match.job.salary_max / 1000)}k`
                : 'Competitive',
              type: 'Full-time',
              skills: match.matched_skills || [],
              url: match.job.url || '#',
              matched_skills: match.matched_skills,
              missing_skills: match.missing_skills,
              match_reason: match.match_reason
            }));

            setJobs(transformedJobs);
          } catch (error) {
            console.error('Error fetching job recommendations:', error);
            // Fall back to sample jobs if API fails
            setJobs(getSampleJobs(skills));
          }
        } else {
          // No skills yet, show sample jobs
          setJobs(getSampleJobs([]));
        }
      }

    } catch (error) {
      console.error('Error loading jobs:', error);
      setJobs(getSampleJobs([]));
    } finally {
      setLoading(false);
    }
  };

  const getSampleJobs = (skills: string[]): Job[] => {
    return [
      {
        id: '1',
        title: 'Junior Frontend Developer',
        company: 'TechCorp',
        location: 'Remote',
        matchScore: skills.length > 0 ? 85 : 50,
        salary: '$60k - $80k',
        type: 'Full-time',
        skills: ['HTML/CSS', 'JavaScript', 'React'],
        url: '#'
      },
      {
        id: '2',
        title: 'Web Developer Intern',
        company: 'StartupX',
        location: 'New York',
        matchScore: skills.length > 0 ? 70 : 40,
        salary: '$45k - $60k',
        type: 'Full-time',
        skills: ['HTML/CSS', 'JavaScript', 'Git'],
        url: '#'
      },
      {
        id: '3',
        title: 'UI Developer',
        company: 'Designly',
        location: 'London',
        matchScore: skills.length > 0 ? 78 : 45,
        salary: '$65k - $85k',
        type: 'Contract',
        skills: ['React', 'Figma', 'CSS'],
        url: '#'
      }
    ];
  };

  const filteredJobs = filter === 'All' 
    ? jobs 
    : jobs.filter(j => j.location.includes(filter) || j.type.includes(filter));

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-slate-600 dark:text-slate-400">Finding jobs for you...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fadeInUp pt-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold">Job Recommendations</h1>
          <p className="text-slate-500">
            {userSkills.length > 0 
              ? `Based on your ${userSkills.length} mastered skills` 
              : 'Complete your profile to get personalized recommendations'
            }
          </p>
        </div>
        <div className="flex bg-white dark:bg-slate-900 p-1 rounded-xl shadow-sm border border-slate-200 dark:border-slate-800">
          {['All', 'Remote', 'Full-time'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg text-sm font-bold transition-all ${
                filter === f 
                  ? 'bg-blue-600 text-white shadow-md' 
                  : 'text-slate-500 hover:text-blue-600'
              }`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {userSkills.length > 0 && (
        <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-2xl p-4">
          <h3 className="text-sm font-bold text-blue-900 dark:text-blue-100 mb-2">
            Your Skills Profile
          </h3>
          <div className="flex flex-wrap gap-2">
            {userSkills.slice(0, 8).map((skill, i) => (
              <span 
                key={i}
                className="bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 px-3 py-1 rounded-full text-xs font-bold"
              >
                {skill}
              </span>
            ))}
            {userSkills.length > 8 && (
              <span className="text-blue-600 dark:text-blue-400 px-3 py-1 text-xs font-bold">
                +{userSkills.length - 8} more
              </span>
            )}
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredJobs.length > 0 ? (
          filteredJobs.map((job) => (
            <div 
              key={job.id} 
              className="bg-white dark:bg-slate-900 rounded-3xl p-6 border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-xl hover:border-blue-300 transition-all flex flex-col group"
            >
              <div className="flex justify-between items-start mb-6">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 bg-slate-100 dark:bg-slate-800 rounded-2xl flex items-center justify-center font-bold text-blue-600 text-lg">
                    {job.company.charAt(0)}
                  </div>
                  <div>
                    <h3 className="font-bold text-lg group-hover:text-blue-600 transition-colors leading-tight">
                      {job.title}
                    </h3>
                    <p className="text-xs text-slate-400 font-semibold">
                      {job.company} • {job.location}
                    </p>
                  </div>
                </div>
                <div className={`px-2 py-1 rounded-lg text-[10px] font-black uppercase tracking-widest ${
                  job.matchScore > 80 
                    ? 'bg-green-100 text-green-700' 
                    : job.matchScore > 60 
                      ? 'bg-blue-100 text-blue-700'
                      : 'bg-orange-100 text-orange-700'
                }`}>
                  {job.matchScore}% Match
                </div>
              </div>

              <p className="text-sm text-slate-600 dark:text-slate-400 mb-6 flex-1">
                {job.match_reason || `Join a fast-growing team. Requires strong knowledge of ${job.skills.slice(0, 2).join(' and ')}.`}
              </p>

              <div className="flex flex-wrap gap-2 mb-6">
                {job.skills.slice(0, 4).map((skill, i) => (
                  <span 
                    key={i} 
                    className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase ${
                      job.matched_skills?.includes(skill)
                        ? 'bg-green-100 text-green-700'
                        : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400'
                    }`}
                  >
                    {skill}
                  </span>
                ))}
              </div>

              <div className="flex items-center justify-between pt-6 border-t border-slate-100 dark:border-slate-800">
                <div className="text-xs">
                  <p className="text-slate-400 font-medium">Salary Range</p>
                  <p className="font-bold text-slate-700 dark:text-slate-200">{job.salary}</p>
                </div>
                <a
                  href={job.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-blue-600 text-white px-6 py-2 rounded-xl text-sm font-bold hover:bg-blue-700 transition-all"
                >
                  Apply Now
                </a>
              </div>
            </div>
          ))
        ) : (
          <div className="col-span-full bg-white dark:bg-slate-900 rounded-3xl p-12 border border-slate-200 dark:border-slate-800 text-center">
            <div className="text-6xl mb-4">💼</div>
            <h3 className="text-xl font-bold mb-2">No jobs found</h3>
            <p className="text-slate-500 mb-6">
              {userSkills.length === 0 
                ? 'Start learning skills to get personalized job recommendations'
                : 'Try adjusting your filter or check back later for new opportunities'
              }
            </p>
            {userSkills.length === 0 && (
              <button 
                onClick={() => window.location.href = '/roadmap'}
                className="bg-blue-600 text-white px-6 py-3 rounded-xl font-bold hover:bg-blue-700 transition"
              >
                Start Learning
              </button>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default Jobs;