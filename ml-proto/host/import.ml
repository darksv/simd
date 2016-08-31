open Source
open Kernel
open Values
open Types

module Unknown = Error.Make ()
exception Unknown = Unknown.Error  (* indicates unknown import name *)

module Registry = Map.Make(String)
let registry = ref Registry.empty

let register name lookup = registry := Registry.add name lookup !registry

let external_type_of_import_kind m ikind =
  match ikind.it with
  | FuncImport x -> ExternalFuncType (List.nth m.it.types x.it)
  | TableImport tab -> ExternalTableType (TableType (tab.it.tlimits, tab.it.etype))
  | MemoryImport mem -> ExternalMemoryType (MemoryType mem.it.mlimits)
  | GlobalImport t -> ExternalGlobalType t

let lookup (m : module_) (imp : import) : Instance.extern =
  let {module_name; item_name; ikind} = imp.it in
  let ty = external_type_of_import_kind m ikind in
  try Registry.find module_name !registry item_name ty with Not_found ->
    Unknown.error imp.at
      ("unknown import \"" ^ module_name ^ "." ^ item_name ^ "\"")

let link m = List.map (lookup m) m.it.imports
