-- This Script is Part of the Prometheus Obfuscator by Levno_710
--
-- pipeline.lua
--
-- This Script Provides some configuration presets

return {
    ["Minify"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "LuaU";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- No obfuscation steps
        Steps = {

        }
    };
    ["Weak"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "LuaU";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables that look like this: IlI1lI1l
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- Obfuscation steps
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    };
    ["Vmify"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "LuaU";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables that look like this: IlI1lI1l
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- Obfuscation steps
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
        }
    };
    ["Medium"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "LuaU";
        -- For minifying no VarNamePrefix is applied
        VarNamePrefix = "";
        -- Name Generator for Variables
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- Obfuscation steps
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {

                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                };
            },
            {
                Name = "AntiParser";
                Settings = {
                    Fast = false; -- full anti-parser strength
                };
            },
            {
                Name = "Vmify";
                Settings = {
                    Fast = true; -- keep compile-time reasonable while preserving most others
                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                    Shuffle     = true;
                    Rotate      = true;
                    LocalWrapperTreshold = 1;
                    LocalWrapperCount = 8;
                    MaxConstants = 256;
                    Encoding = "mixed";
                    Fast = true; 
                }
            },
            {
                Name = "NumbersToExpressions";
                Settings = {

                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    };
    ["Fast"] = {
        -- Fast preset for quick local development with reduced strength
        LuaVersion = "LuaU";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {

                };
            };
            {
                Name = "AntiTamper";
                Settings = {
                    Fast = true;
                };
            };
            {
                Name = "AntiParser";
                Settings = {
                    Fast = true;
                };
            };
            {
                Name = "Vmify";
                Settings = {
                    Fast = true;
                };
            };
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 1;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = true;
                    LocalWrapperTreshold = 0;
                    MaxConstants = 256;
                    Encoding = "mixed";
                };
            };
            {
                Name = "NumbersToExpressions";
                Settings = {

                };
            };
            {
                Name = "WrapInFunction";
                Settings = {

                };
            };
        };
    };
    ["Balanced"] = {
        -- Balanced preset: AntiParser + AntiTamper moderate, fewer heavy vm ops by default
        LuaVersion = "LuaU";
        VarNamePrefix = "";
        NameGenerator = "MangledShuffled";
        PrettyPrint = false;
        Seed = 0;
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {};
            };
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                    Fast = false;
                };
            };
            {
                Name = "AntiParser";
                Settings = {
                    Fast = false;
                };
            };
            {
                Name = "Vmify";
                Settings = {
                    Fast = true; -- reasonable performance while anti checks remain strong
                };
            };
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold = 1;
                    StringsOnly = true;
                    Shuffle = true;
                    Rotate = true;
                    LocalWrapperTreshold = 0;
                    MaxConstants = 512;
                    Encoding = "mixed";
                };
            };
            {
                Name = "NumbersToExpressions";
                Settings = {};
            };
            {
                Name = "WrapInFunction";
                Settings = {};
            };
        };
    };
    ["Strong"] = {
        -- The default LuaVersion is Lua51
        LuaVersion = "LuaU";
        VarNamePrefix = "";
        -- Name Generator for Variables that look like this: IlI1lI1l
        NameGenerator = "MangledShuffled";
        -- No pretty printing
        PrettyPrint = false;
        -- Seed is generated based on current time
        Seed = 0;
        -- Obfuscation steps
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "EncryptStrings";
                Settings = {

                };
            },
            {
                Name = "AntiTamper";
                Settings = {

                };
            },
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                    Shuffle     = true;
                    Rotate      = true;
                    LocalWrapperTreshold = 0;
                }
            },
            {
                Name = "NumbersToExpressions";
                Settings = {

                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    },
}
