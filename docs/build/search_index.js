var documenterSearchIndex = {"docs":
[{"location":"index.html#ModelParams","page":"ModelParams","title":"ModelParams","text":"","category":"section"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"The purpose of ModelParams is to offer an automated workflow for handling model objects and their potentially calibrated or estimated parameters.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"CurrentModule = ModelParams","category":"page"},{"location":"index.html#Background","page":"ModelParams","title":"Background","text":"","category":"section"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"The target audience consists mainly of economists who calibrate or estimate structural models.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"One may think of a model as a collection of model objects, such as utility functions, production functions, etc. Model objects may contain nested model objects. For example, a household model object may contain a utility function.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"Typically, a researcher will calibrate many model versions that differ in:","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"functional forms (e.g., log utility versus CARA)\nwhich parameters are fixed versus calibrated\nswitches (e.g., does the model have preference shocks? How many types of households are there?)","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"The challenge is then to keep track of:","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"which fixed parameters need to be set?\nwhich parameters need to be calibrated?\nwhere to put the calibrated parameter values in the model?","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"In addition, one needs to keep track of which data moments are used in the calibration and what the associated model moments are.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"All of this is automated in ModelParams.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"To see in action how this works, see the SampleModel repo in my github account.","category":"page"},{"location":"index.html#Parameters:-[Param](@ref)","page":"ModelParams","title":"Parameters: Param","text":"","category":"section"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"Model parameters that are either calibrated or fixed are defined in Param objects. These encode default values (used when not calibrated), bounds, Latex symbols, and descriptions.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"Vectors that are increasing are encoded in an IncreasingVector.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"IncreasingVector\nvalues","category":"page"},{"location":"index.html#ModelParams.IncreasingVector","page":"ModelParams","title":"ModelParams.IncreasingVector","text":"IncreasingVector\n\nEncodes an increasing vector of fixed length. Its values are calibrated.\n\n\n\n\n\n","category":"type"},{"location":"index.html#Base.values","page":"ModelParams","title":"Base.values","text":"Retrieve values of an IncreasingVector.\n\n\n\n\n\nReturns all values of a BoundedVector.\n\n\n\n\n\nvalues(iv, idx)\n\n\nReturns a subset of the values of a BoundedVector.\n\n\n\n\n\n","category":"function"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"BoundedVector encodes a vector that is monotone and bounded.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"BoundedVector\nset_pvector!\nset_default_value!\nfix_values!","category":"page"},{"location":"index.html#ModelParams.BoundedVector","page":"ModelParams","title":"ModelParams.BoundedVector","text":"Increasing or decreasing vector with bounds. The special case where the vector is of length 1 is supported.\n\nA BoundedVector is typically constructed with an empty ParamVector. Then set_pvector! is used to initialize the ParamVector. The ParamVector contains a single entry which must be named :dxV. It sets the values for the eponymous BoundedVector field. The dxV are typically in [0, 1]. They represent the increments in the vector.\n\n\n\n\n\n","category":"type"},{"location":"index.html#ModelParams.set_pvector!","page":"ModelParams","title":"ModelParams.set_pvector!","text":"set_pvector!(iv; description, symbol, isCalibrated)\n\n\nInitialize the ParamVector. Requires dxV to be set. Note that bounds on dxV must be between 0 and 1. This is called after the BoundedVector has been constructed with an empty ParamVector but with the values of the field dxV set to reasonable defaults.\n\nExample\n\ndxV = [0.3, 0.2, 0.8];\nb = BoundedVector(objId, ParamVector(objId), true, 1.0, 2.0, dxV);\nset_pvector!(b; description = \"Gradient\", symbol = \"g(x)\");\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.set_default_value!","page":"ModelParams","title":"ModelParams.set_default_value!","text":"set_default_value!(iv, valueV)\n\n\nSet the default values of a BoundedVector.\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.fix_values!","page":"ModelParams","title":"ModelParams.fix_values!","text":"Switches calibration toggle off. Sets values and default values everywhere. The end result is a BoundedVector with fixed (not calibrated) increments that result in values of valueV.\n\n\n\n\n\n","category":"function"},{"location":"index.html#Parameter-Vectors:-ParamVector","page":"ModelParams","title":"Parameter Vectors: ParamVector","text":"","category":"section"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"The second key concept is a ParamVector. It collects all potentially calibrated model parameters, represented as Param objects.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"For convenience and performance, a ModelObject has a field for each Param. The field values should never be written to \"by hand.\" Functions are provided that sync fixed and calibrated parameters from the ParamVector.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"To enable unambiguous matching of ParamVectors to child objects, each ParamVector contains the object's ObjectId.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"ParamVector\nParam","category":"page"},{"location":"index.html#ModelParams.ParamVector","page":"ModelParams","title":"ModelParams.ParamVector","text":"ParamVector\n\nVector containing all of a model's potentially calibrated parameters. Parameters contain values, not just default values They are kept in sync with values in object\n\nIntended workflow:     See SampleModel     Create a model object with parameters as fields         Otherwise the code gets too cumbersome         Constructor initializes ParamVector with defaults (or user inputs)     During calibration         Each object generates a Dict of calibrated parameters         Make this into a vector of Floats that can be passed to the optimizer.         Optimization algorithm changes the floats         Make floats back into Dict         Copy back into model objects\n\nGoing from a vector of Dicts to a vector of Floats and back:     make_guess     set_params_from_guess!     These are called on the top level model object\n\nToDo: Make the process of going from model -> vector and vice versa more robust.\n\nCurrently, the user has to ensure that the ordering of ParamVectors and model\nobjects never changes.\n\n\n\n\n\n","category":"type"},{"location":"index.html#ModelParams.Param","page":"ModelParams","title":"ModelParams.Param","text":"Param\n\nHolds information about one potentially calibrated parameter (array). Default value must always be set. Determines size of inputs. Everything else can be either empty or must have the same size.\n\n\n\n\n\n","category":"type"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"Useful access routines for ParamVectors include:","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"retrieve\nappend!\nremove!\nreplace!\nchange_calibration_status!\nchange_value!","category":"page"},{"location":"index.html#ModelParams.retrieve","page":"ModelParams","title":"ModelParams.retrieve","text":"retrieve\n\nReturns a named parameter and its index in the ParamVector. First occurrence. Returns 0 if not found.\n\n\n\n\n\n","category":"function"},{"location":"index.html#Base.append!","page":"ModelParams","title":"Base.append!","text":"append!\n\nAppend a Param to a ParamVector\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.remove!","page":"ModelParams","title":"ModelParams.remove!","text":"remove!(pvec, pName)\n\n\nRemove the parameter names pName from pvec.\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.replace!","page":"ModelParams","title":"ModelParams.replace!","text":"replace!(pvec, p)\n\n\nReplace a parameter with a new parameter p.\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.change_calibration_status!","page":"ModelParams","title":"ModelParams.change_calibration_status!","text":"change_calibration_status!(pvec, pName, doCal)\n\n\nSet whether or not a parameter is calibrated.\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.change_value!","page":"ModelParams","title":"ModelParams.change_value!","text":"change_value!(pvec, pName, newValue)\n\n\nChange the value of parameter pName.\n\n\n\n\n\nchange_value!(x, oName, pName, newValue)\n\n\nChange value of a field in a ModelObject and its ParamVector.\n\n\n\n\n\n","category":"function"},{"location":"index.html#Vectors-of-ParamVector","page":"ModelParams","title":"Vectors of ParamVector","text":"","category":"section"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"These are used when all the ParamVectors from a ModelObject are collected.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"find_pvector","category":"page"},{"location":"index.html#ModelParams.find_pvector","page":"ModelParams","title":"ModelParams.find_pvector","text":"find_pvector(pvv, objId)\n\n\nFind a ParamVector for a given ObjectId.  Returns index and the ParamVector. Or 0 and nothing if not found.\n\n\n\n\n\n","category":"function"},{"location":"index.html#Calibrating-a-model","page":"ModelParams","title":"Calibrating a model","text":"","category":"section"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"The workflow is implemented and tested in the SampleModel repo.","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"Initialize a model object, including its child objects. E.g., SampleModel.Model.\nWrite the code and solves the model and computes any desired statistics. This part is not affected by anything related to ModelParams because the potentially calibrated parameters are stored inside each object and synced with the ParamVectors.\nWrite a deviation function that accepts a vector of calibrated parameters as an input. Call set_params_from_guess! to copy the parameter values from the vector into the various model objects.\nIn the calibration function, call make_guess to make a vector of parameter values from the parameter values in all of the model objects.\nReport the calibrated and fixed parameters using report_params","category":"page"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"set_params_from_guess!\nmake_guess\nreport_params\nparam_tables","category":"page"},{"location":"index.html#ModelParams.set_params_from_guess!","page":"ModelParams","title":"ModelParams.set_params_from_guess!","text":"set_params_from_guess!(m, guess)\n\n\nMake vector of guesses into model parameters. For object and children. This changes the values in m and in its pvector.\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.make_guess","page":"ModelParams","title":"ModelParams.make_guess","text":"make_guess(m)\n\n\nMake vector of parameters and bounds for an object Including nested objects\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.report_params","page":"ModelParams","title":"ModelParams.report_params","text":"report_params(pvec, isCalibrated; io, closeToBounds)\n\n\nReports calibrated (or fixed) parameters for one ParamVector as a PrettyTable.\n\n\n\n\n\nreport_params(o, isCalibrated; io, closeToBounds)\n\n\nReport all parameters by calibration status. For all ModelObjects contained in o.\n\nIntended for reporting at the end (or during) a calibration run. Not formatted for inclusion in papers.\n\nEach table row looks like: \"Description (name): value\"\n\n\n\n\n\n","category":"function"},{"location":"index.html#ModelParams.param_tables","page":"ModelParams","title":"ModelParams.param_tables","text":"param_tables(o, isCalibrated)\n\n\nGenerate a set of ParamTables. One table per model object. These are stored in a Dict with ObjectId's as keys.\n\nThe purpose is to make it easy to generate nicely formatted parameter tables that are grouped in a sensible way.\n\n\n\n\n\n","category":"function"},{"location":"index.html","page":"ModelParams","title":"ModelParams","text":"","category":"page"}]
}
