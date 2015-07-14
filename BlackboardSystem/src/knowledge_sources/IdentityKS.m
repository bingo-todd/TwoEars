classdef IdentityKS < AuditoryFrontEndDepKS
    
    properties (SetAccess = private)
        modelname;
        model;                 % classifier model
        featureCreator;
    end

    methods
        function obj = IdentityKS( modelName, modelVersion )
            modelFileName = [modelName '.' modelVersion];
            v = load( [modelFileName '.model.mat'] );
            if ~isa( v.featureCreator, 'FeatureProcInterface' )
                error( 'Loaded model''s featureCreator must implement FeatureProcInterface.' );
            end
            obj = obj@AuditoryFrontEndDepKS( v.featureCreator.getAFErequests() );
            obj.featureCreator = v.featureCreator;
            obj.model = v.model;
            obj.modelname = modelName;
            obj.invocationMaxFrequency_Hz = 4;
       end
        
        %% utility function for printing the obj
        function s = char( obj )
            s = [char@AuditoryFrontEndDepKS( obj ), '[', obj.modelname, ']'];
        end
        
        %% execute functionality
        function [b, wait] = canExecute( obj )
            b = true;
            wait = false;
        end
        
        function execute( obj )
            afeData = obj.getAFEdata();
            afeData = obj.featureCreator.cutDataBlock( afeData, obj.timeSinceTrigger );
            
            x = obj.featureCreator.makeDataPoint( afeData );
            [~, score] = obj.model.applyModel( x );
            
            if obj.blackboard.verbosity > 0
                fprintf( 'Identity Hypothesis: %s with %i%% probability.\n', ...
                    obj.modelname, int16(score(1)*100) );
            end
            identHyp = IdentityHypothesis( obj.modelname, score(1), obj.blocksize_s );
            obj.blackboard.addData( 'identityHypotheses', identHyp, true, obj.trigger.tmIdx );
            notify( obj, 'KsFiredEvent', BlackboardEventData( obj.trigger.tmIdx ) );
        end
    end
end