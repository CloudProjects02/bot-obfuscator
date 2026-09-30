local Legacy = require("./Instance/legacy_impl")

Legacy.Core = require("./Instance/core")
Legacy.PropertiesBridge = require("./Instance/properties_bridge")
Legacy.MethodDispatch = require("./Instance/method_dispatch")
Legacy.ParentingCloneDestroy = require("./Instance/parenting_clone_destroy")
Legacy.TagsAndAttributes = require("./Instance/tags_and_attributes")
Legacy.ScriptObjects = require("./Instance/script_objects")

return Legacy