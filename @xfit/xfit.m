%                                      _            
%  _ __  _ __ ___   ___ _ __ _   _ ___| |_ ___  ___ 
% | '_ \| '__/ _ \ / __| '__| | | / __| __/ _ \/ __|
% | |_) | | | (_) | (__| |  | |_| \__ \ ||  __/\__ \
% | .__/|_|  \___/ \___|_|   \__,_|___/\__\___||___/
% |_|  
%
% xfit is a toolbox that attempts
% to change parameters in a Xolotl object
% so that it fits some arbitrary set of conditions

classdef xfit < handle

properties
	x@xolotl

	% function to minimize
	sim_func@function_handle

	% parameters to optimize
	parameter_names@cell
	seed
	lb
	ub

	options

	display_type = 'iter'
	engine 

	% logging
	timestamp
	best_cost

	% this can be used to store any user-defined data
	data


end % end props

methods
	function self = xfit(engine)
		% check for optimisation toolbox
		v = ver;
		gcp;
		if nargin ==0 
			engine = 'particleswarm';
		end
		assert(any(strcmp('Optimization Toolbox', {v.Name})),'optimisation toolbox is required')
		assert(any(strcmp('Global Optimization Toolbox', {v.Name})),'Global Optimization Toolbox is required')
		self.engine = engine;

	end % end constructor

	function self = set.x(self,value)
		value.closed_loop = false;
		assert(length(value) == 1,'Only one Xolotl object at a time')
		self.x = value;
	end


	function self = set.parameter_names(self,names)
		% check that a xolotl object is configured
		assert(~isempty(self.x),'First configure a xolotl object')

		% check that they all resolve correctly
		for i = 1:length(names)
			try
				self.x.get(names{i});
			catch
				
				error(['This name does not resolve to anything in the xolotl object tree: ' names{i}])
			end
			
		end
		self.parameter_names = names;
	end



	function self = set.engine(self,value)
		pool = gcp;
		switch value 
		case 'patternsearch'
			self.engine = 'patternsearch';
			self.options = optimoptions('patternsearch');
			self.options.UseParallel = true;
			self.options.Display = 'iter';
			self.options.MaxTime = 100;
			self.options.OutputFcn = @self.pattern_logger;
		case 'particleswarm'
			self.engine = 'particleswarm';
			self.options = optimoptions('particleswarm');
			self.options.UseParallel = true;
			self.options.ObjectiveLimit = 0;
			self.options.Display = 'iter';
			self.options.MaxTime = 100;
			self.options.OutputFcn = @self.swarm_logger;
			self.options.SwarmSize = 2*pool.NumWorkers;
		case 'ga'
			self.engine = 'ga';
			self.options = optimoptions('ga');
			self.options.UseParallel = true;
			self.options.FitnessLimit = 0;
			self.options.Display = 'iter';
			self.options.MaxTime = 100;
			self.options.OutputFcn = @self.ga_logger;
		otherwise 
			error('Unknown engine')
		end
	end % set engine

	function stop = swarm_logger(self,optimValues,~)
		stop = false;

		self.best_cost(optimValues.iteration+1) = optimValues.bestfval;
		self.timestamp(optimValues.iteration+1) = now;

	end

	function [stop, options, optchanged] = pattern_logger(self,optimValues,options,~)
		stop = false;
		optchanged = false;
		self.best_cost(optimValues.iteration+1) = optimValues.fval;
		self.timestamp(optimValues.iteration+1) = now;
	end

	function [state, options, optchanged] = ga_logger(self, options, state, flag)
		optchanged = false;
		self.best_cost(state.Generation + 1) = min(state.Score);
		self.timestamp(state.Generation + 1) = now;
	end % end ga logger

end % end methods


methods (Static)
	b = binCost(r,a);
end



end % end classdef
