(*
   Copyright (C) 2024 International Digital Economy Academy.
   This program is licensed under the MoonBit Public Source
   License as published by the International Digital Economy Academy,
   either version 1 of the License, or (at your option) any later
   version. This program is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the MoonBit
   Public Source License for more details. You should have received a
   copy of the MoonBit Public Source License along with this program. If
   not, see
   <https://www.moonbitlang.com/licenses/moonbit-public-source-license-v1>.
*)


module Qual_ident = Basic_qual_ident
module Core_ident = Basic_core_ident
module Strutil = Basic_strutil
module Uuid = Basic_uuid
module Hash_gen = Basic_hash_gen
module Hashset_gen = Basic_hashset_gen
module Ordered_hash_map_gen = Basic_ordered_hash_map_gen

module Key = struct
  type t =
    | Pdot of { qual_name : Qual_ident.t; ty : Ltype.t [@ceh.ignore] }
    | Pident of {
        stamp : int;
        name : string; [@ceh.ignore]
        ty : Ltype.t; [@ceh.ignore]
      }
    | Pmutable_ident of {
        stamp : int;
        name : string; [@ceh.ignore]
        ty : Ltype.t; [@ceh.ignore]
      }

  include struct
    let _ = fun (_ : t) -> ()

    let (hash_fold_t : Ppx_base.state -> t -> Ppx_base.state) =
      (fun hsv ->
         fun arg ->
          match arg with
          | Pdot _ir ->
              let hsv = Ppx_base.hash_fold_int hsv 0 in
              let hsv =
                let hsv = hsv in
                Qual_ident.hash_fold_t hsv _ir.qual_name
              in
              hsv
          | Pident _ir ->
              let hsv = Ppx_base.hash_fold_int hsv 1 in
              let hsv =
                let hsv =
                  let hsv = hsv in
                  Ppx_base.hash_fold_int hsv _ir.stamp
                in
                hsv
              in
              hsv
          | Pmutable_ident _ir ->
              let hsv = Ppx_base.hash_fold_int hsv 2 in
              let hsv =
                let hsv =
                  let hsv = hsv in
                  Ppx_base.hash_fold_int hsv _ir.stamp
                in
                hsv
              in
              hsv
        : Ppx_base.state -> t -> Ppx_base.state)

    let _ = hash_fold_t

    let (hash : t -> Ppx_base.hash_value) =
      let func arg =
        Ppx_base.get_hash_value
          (let hsv = Ppx_base.create () in
           hash_fold_t hsv arg)
      in
      fun x -> func x

    let _ = hash
  end

  let compare (x : t) (y : t) =
    match x with
    | Pident { stamp = x; _ } | Pmutable_ident { stamp = x; _ } -> (
        match y with
        | Pident { stamp = y; _ } | Pmutable_ident { stamp = y; _ } ->
            Int.compare x y
        | Pdot _ -> -1)
    | Pdot x -> (
        match y with
        | Pident _ | Pmutable_ident _ -> 1
        | Pdot y -> Qual_ident.compare x.qual_name y.qual_name)

  let equal (x : t) (y : t) =
    match x with
    | Pident { stamp = x; _ } | Pmutable_ident { stamp = x; _ } -> (
        match y with
        | Pident { stamp = y; _ } | Pmutable_ident { stamp = y; _ } -> x = y
        | Pdot _ -> false)
    | Pdot x -> (
        match y with
        | Pident _ | Pmutable_ident _ -> false
        | Pdot y -> Qual_ident.equal x.qual_name y.qual_name)

  let to_string (x : t) =
    match x with
    | Pident { name; stamp; ty = _ } -> name ^ "/" ^ string_of_int stamp
    | Pmutable_ident { name; stamp; ty = _ } -> name ^ "!" ^ string_of_int stamp
    | Pdot q -> Qual_ident.string_of_t q.qual_name

  let sexp_of_t (x : t) =
    (let ty =
       match x with
       | Pdot { ty; _ } | Pident { ty; _ } | Pmutable_ident { ty; _ } ->
           Ltype.sexp_of_t ty
     in
     List [ Atom (to_string x); Atom ":"; ty ]
      : S.t)
end

include Key

let of_qual_ident (qual_name : Qual_ident.t) ~ty = (Pdot { qual_name; ty } : t)

let of_core_ident (x : Core_ident.t) ~ty =
  (match x with
   | Pdot qual_name -> Pdot { qual_name; ty }
   | Plocal_method _ -> assert false
   | Pident { stamp; name } -> Pident { stamp; name; ty }
   | Pmutable_ident { stamp; name } -> Pmutable_ident { stamp; name; ty }
    : t)

let to_wasm_name (x : t) =
  match x with
  | Pident { name; stamp; ty = _ } | Pmutable_ident { name; stamp; ty = _ } ->
      let name = Strutil.mangle_wasm_name name in
      (Stdlib.String.concat ""
         [ "$"; name; "/"; Int.to_string stamp ] [@merlin.hide])
  | Pdot { qual_name; ty = _ } -> Qual_ident.to_wasm_name qual_name

let fresh name ~ty = Pident { name; stamp = Uuid.next (); ty }

let get_type (x : t) =
  match x with
  | Pident { ty; _ } | Pmutable_ident { ty; _ } | Pdot { ty; _ } -> ty

let source_name (x : t) =
  match x with
  | Pdot { qual_name; _ } -> Qual_ident.string_of_t qual_name
  | Pident { name; _ } -> name
  | Pmutable_ident { name; _ } -> name

module Map = struct
  module Map_gen = Basic_map_gen
  module Lst = Basic_lst
  module Arr = Basic_arr

  type key = Key.t
  type +'a t = (key, 'a) Map_gen.t

  let empty = Map_gen.empty
  let is_empty = Map_gen.is_empty
  let iter = Map_gen.iter
  let fold = Map_gen.fold
  let for_all = Map_gen.for_all
  let exists = Map_gen.exists
  let singleton = Map_gen.singleton
  let cardinal = Map_gen.cardinal
  let bindings = Map_gen.bindings
  let to_sorted_array = Map_gen.to_sorted_array
  let to_sorted_array_with_f = Map_gen.to_sorted_array_with_f
  let keys = Map_gen.keys
  let map = Map_gen.map
  let mapi = Map_gen.mapi
  let bal = Map_gen.bal
  let height = Map_gen.height

  let rec add (tree : _ Map_gen.t as 'a) x data =
    (match tree with
     | Empty -> singleton x data
     | Leaf { k; v } ->
         let c = Key.compare x k in
         if c = 0 then singleton x data
         else if c < 0 then Map_gen.unsafe_two_elements x data k v
         else Map_gen.unsafe_two_elements k v x data
     | Node { l; k; v; r; h } ->
         let c = Key.compare x k in
         if c = 0 then Map_gen.unsafe_node x data l r h
         else if c < 0 then bal (add l x data) k v r
         else bal l k v (add r x data)
      : 'a)

  let rec adjust (tree : _ Map_gen.t as 'a) x replace =
    (match tree with
     | Empty -> singleton x (replace None)
     | Leaf { k; v } ->
         let c = Key.compare x k in
         if c = 0 then singleton x (replace (Some v))
         else if c < 0 then Map_gen.unsafe_two_elements x (replace None) k v
         else Map_gen.unsafe_two_elements k v x (replace None)
     | Node ({ l; k; r; _ } as tree) ->
         let c = Key.compare x k in
         if c = 0 then Map_gen.unsafe_node x (replace (Some tree.v)) l r tree.h
         else if c < 0 then bal (adjust l x replace) k tree.v r
         else bal l k tree.v (adjust r x replace)
      : 'a)

  let rec find_exn (tree : _ Map_gen.t) x =
    match tree with
    | Empty -> raise Not_found
    | Leaf leaf -> if Key.equal x leaf.k then leaf.v else raise Not_found
    | Node tree ->
        let c = Key.compare x tree.k in
        if c = 0 then tree.v else find_exn (if c < 0 then tree.l else tree.r) x

  let rec find_opt (tree : _ Map_gen.t) x =
    match tree with
    | Empty -> None
    | Leaf leaf -> if Key.equal x leaf.k then Some leaf.v else None
    | Node tree ->
        let c = Key.compare x tree.k in
        if c = 0 then Some tree.v
        else find_opt (if c < 0 then tree.l else tree.r) x

  let rec find_default (tree : _ Map_gen.t) x default =
    match tree with
    | Empty -> default
    | Leaf leaf -> if Key.equal x leaf.k then leaf.v else default
    | Node tree ->
        let c = Key.compare x tree.k in
        if c = 0 then tree.v
        else find_default (if c < 0 then tree.l else tree.r) x default

  let rec mem (tree : _ Map_gen.t) x =
    match tree with
    | Empty -> false
    | Leaf leaf -> Key.equal x leaf.k
    | Node { l; k; r; _ } ->
        let c = Key.compare x k in
        c = 0 || mem (if c < 0 then l else r) x

  let rec remove (tree : _ Map_gen.t as 'a) x =
    (match tree with
     | Empty -> empty
     | Leaf leaf -> if Key.equal x leaf.k then empty else tree
     | Node { l; k; v; r; _ } ->
         let c = Key.compare x k in
         if c = 0 then Map_gen.merge l r
         else if c < 0 then bal (remove l x) k v r
         else bal l k v (remove r x)
      : 'a)

  type 'a split =
    | Yes of { l : (key, 'a) Map_gen.t; r : (key, 'a) Map_gen.t; v : 'a }
    | No of { l : (key, 'a) Map_gen.t; r : (key, 'a) Map_gen.t }

  let rec split (tree : (key, 'a) Map_gen.t) x =
    (match tree with
     | Empty -> No { l = empty; r = empty }
     | Leaf leaf ->
         let c = Key.compare x leaf.k in
         if c = 0 then Yes { l = empty; v = leaf.v; r = empty }
         else if c < 0 then No { l = empty; r = tree }
         else No { l = tree; r = empty }
     | Node { l; k; v; r; _ } -> (
         let c = Key.compare x k in
         if c = 0 then Yes { l; v; r }
         else if c < 0 then
           match split l x with
           | Yes result -> Yes { result with r = Map_gen.join result.r k v r }
           | No result -> No { result with r = Map_gen.join result.r k v r }
         else
           match split r x with
           | Yes result -> Yes { result with l = Map_gen.join l k v result.l }
           | No result -> No { result with l = Map_gen.join l k v result.l })
      : 'a split)

  let rec disjoint_merge_exn (s1 : _ Map_gen.t) (s2 : _ Map_gen.t) fail =
    (match s1 with
     | Empty -> s2
     | Leaf ({ k; _ } as l1) -> (
         match s2 with
         | Empty -> s1
         | Leaf l2 ->
             let c = Key.compare k l2.k in
             if c = 0 then raise_notrace (fail k l1.v l2.v)
             else if c < 0 then Map_gen.unsafe_two_elements l1.k l1.v l2.k l2.v
             else Map_gen.unsafe_two_elements l2.k l2.v k l1.v
         | Node _ ->
             adjust s2 k (fun data ->
                 match data with
                 | None -> l1.v
                 | Some s2v -> raise_notrace (fail k l1.v s2v)))
     | Node ({ k; _ } as xs1) -> (
         if xs1.h >= height s2 then
           match split s2 k with
           | No { l; r } ->
               Map_gen.join
                 (disjoint_merge_exn xs1.l l fail)
                 k xs1.v
                 (disjoint_merge_exn xs1.r r fail)
           | Yes { v = s2v; _ } -> raise_notrace (fail k xs1.v s2v)
         else
           match[@warning "-fragile-match"] s2 with
           | (Node ({ k; _ } as s2) : _ Map_gen.t) -> (
               match split s1 k with
               | No { l; r } ->
                   Map_gen.join
                     (disjoint_merge_exn l s2.l fail)
                     k s2.v
                     (disjoint_merge_exn r s2.r fail)
               | Yes { v = s1v; _ } -> raise_notrace (fail k s1v s2.v))
           | _ -> assert false)
      : _ Map_gen.t)

  let sexp_of_t f map =
    Moon_sexp_conv.sexp_of_list
      (fun (k, v) ->
        let a = Key.sexp_of_t k in
        let b = f v in
        List [ a; b ])
      (bindings map)

  let add_list (xs : _ list) init =
    Lst.fold_left xs init (fun acc -> fun (k, v) -> add acc k v)

  let of_list xs = add_list xs empty

  let of_array xs =
    Arr.fold_left xs empty (fun acc -> fun (k, v) -> add acc k v)
end

module Set = struct
  module Set_gen = Basic_set_gen
  module Lst = Basic_lst

  type elt = Key.t
  type 'a t0 = 'a Set_gen.t
  type t = elt t0

  let empty = Set_gen.empty
  let is_empty = Set_gen.is_empty
  let iter = Set_gen.iter
  let fold = Set_gen.fold
  let for_all = Set_gen.for_all
  let exists = Set_gen.exists
  let singleton = Set_gen.singleton
  let cardinal = Set_gen.cardinal
  let elements = Set_gen.elements
  let choose = Set_gen.choose
  let to_list = Set_gen.to_list
  let map_to_list = Set_gen.map_to_list
  let of_sorted_array = Set_gen.of_sorted_array

  let rec mem (tree : t) (x : elt) =
    match tree with
    | Empty -> false
    | Leaf v -> Key.equal x v
    | Node { l; v; r; _ } ->
        let c = Key.compare x v in
        c = 0 || mem (if c < 0 then l else r) x

  type split = Yes of { l : t; r : t } | No of { l : t; r : t }

  let split_l (x : split) = match x with Yes { l; _ } | No { l; _ } -> l
  [@@inline]

  let split_r (x : split) = match x with Yes { r; _ } | No { r; _ } -> r
  [@@inline]

  let split_pres (x : split) = match x with Yes _ -> true | No _ -> false
  [@@inline]

  let rec split (tree : t) x =
    (match tree with
     | Empty -> No { l = empty; r = empty }
     | Leaf v ->
         let c = Key.compare x v in
         if c = 0 then Yes { l = empty; r = empty }
         else if c < 0 then No { l = empty; r = tree }
         else No { l = tree; r = empty }
     | Node { l; v; r; _ } -> (
         let c = Key.compare x v in
         if c = 0 then Yes { l; r }
         else if c < 0 then
           match split l x with
           | Yes result ->
               Yes { result with r = Set_gen.internal_join result.r v r }
           | No result ->
               No { result with r = Set_gen.internal_join result.r v r }
         else
           match split r x with
           | Yes result ->
               Yes { result with l = Set_gen.internal_join l v result.l }
           | No result ->
               No { result with l = Set_gen.internal_join l v result.l })
      : split)

  let rec add (tree : t) x =
    (match tree with
     | Empty -> singleton x
     | Leaf v ->
         let c = Key.compare x v in
         if c = 0 then tree
         else if c < 0 then Set_gen.unsafe_two_elements x v
         else Set_gen.unsafe_two_elements v x
     | Node { l; v; r; _ } as t ->
         let c = Key.compare x v in
         if c = 0 then t
         else if c < 0 then Set_gen.bal (add l x) v r
         else Set_gen.bal l v (add r x)
      : t)

  let rec check_add (tree : t) ~(duplicate_flag : bool ref) (x : elt) =
    (match tree with
     | Empty -> singleton x
     | Leaf v ->
         let c = Key.compare x v in
         if c = 0 then (
           duplicate_flag := true;
           tree)
         else if c < 0 then Set_gen.unsafe_two_elements x v
         else Set_gen.unsafe_two_elements v x
     | Node { l; v; r; _ } ->
         let c = Key.compare x v in
         if c = 0 then tree
         else if c < 0 then Set_gen.bal (check_add l ~duplicate_flag x) v r
         else Set_gen.bal l v (check_add r ~duplicate_flag x)
      : t)

  let rec union (s1 : t) (s2 : t) =
    (match (s1, s2) with
     | Empty, t | t, Empty -> t
     | Node _, Leaf v2 -> add s1 v2
     | Leaf v1, Node _ -> add s2 v1
     | Leaf x, Leaf v ->
         let c = Key.compare x v in
         if c = 0 then s1
         else if c < 0 then Set_gen.unsafe_two_elements x v
         else Set_gen.unsafe_two_elements v x
     | ( Node { l = l1; v = v1; r = r1; h = h1 },
         Node { l = l2; v = v2; r = r2; h = h2 } ) ->
         if h1 >= h2 then
           let split_result = split s2 v1 in
           Set_gen.internal_join
             (union l1 (split_l split_result))
             v1
             (union r1 (split_r split_result))
         else
           let split_result = split s1 v2 in
           Set_gen.internal_join
             (union (split_l split_result) l2)
             v2
             (union (split_r split_result) r2)
      : t)

  let rec inter (s1 : t) (s2 : t) =
    (match (s1, s2) with
     | Empty, _ | _, Empty -> empty
     | Leaf v, _ -> if mem s2 v then s1 else empty
     | Node ({ v; _ } as s1), _ ->
         let result = split s2 v in
         if split_pres result then
           Set_gen.internal_join
             (inter s1.l (split_l result))
             v
             (inter s1.r (split_r result))
         else
           Set_gen.internal_concat
             (inter s1.l (split_l result))
             (inter s1.r (split_r result))
      : t)

  let rec diff (s1 : t) (s2 : t) =
    (match (s1, s2) with
     | Empty, _ -> empty
     | t1, Empty -> t1
     | Leaf v, _ -> if mem s2 v then empty else s1
     | Node ({ v; _ } as s1), _ ->
         let result = split s2 v in
         if split_pres result then
           Set_gen.internal_concat
             (diff s1.l (split_l result))
             (diff s1.r (split_r result))
         else
           Set_gen.internal_join
             (diff s1.l (split_l result))
             v
             (diff s1.r (split_r result))
      : t)

  let rec remove (tree : t) (x : elt) =
    (match tree with
     | Empty -> empty
     | Leaf v -> if Key.equal x v then empty else tree
     | Node { l; v; r; _ } ->
         let c = Key.compare x v in
         if c = 0 then Set_gen.internal_merge l r
         else if c < 0 then Set_gen.bal (remove l x) v r
         else Set_gen.bal l v (remove r x)
      : t)

  let of_list l =
    match l with
    | [] -> empty
    | x0 :: [] -> singleton x0
    | [ x0; x1 ] -> add (singleton x0) x1
    | [ x0; x1; x2 ] -> add (add (singleton x0) x1) x2
    | [ x0; x1; x2; x3 ] -> add (add (add (singleton x0) x1) x2) x3
    | [ x0; x1; x2; x3; x4 ] -> add (add (add (add (singleton x0) x1) x2) x3) x4
    | x0 :: x1 :: x2 :: x3 :: x4 :: rest ->
        let init = add (add (add (add (singleton x0) x1) x2) x3) x4 in
        Lst.fold_left rest init add

  let invariant t =
    Set_gen.check t;
    Set_gen.is_ordered ~cmp:Key.compare t

  let add_list (env : t) params =
    (List.fold_left (fun env -> fun e -> add env e) env params : t)

  let sexp_of_t t = Moon_sexp_conv.sexp_of_list Key.sexp_of_t (to_list t)

  let filter t f =
    let nt = ref empty in
    iter t (fun e -> if f e then nt := add !nt e);
    !nt
end

module Hash = struct
  type key = t

  include struct
    let _ = fun (_ : key) -> ()
    let sexp_of_key = (sexp_of_t : key -> S.t)
    let _ = sexp_of_key
    let equal_key = (equal : key -> key -> bool)
    let _ = equal_key
  end

  type 'a t = (key, 'a) Hash_gen.t

  let key_index (h : _ t) (key : key) = hash key land (Array.length h.data - 1)

  module Lst = Basic_lst
  module Unsafe_external = Basic_unsafe_external
  open Unsafe_external

  exception Key_not_found of key

  type ('a, 'b) bucket = ('a, 'b) Hash_gen.bucket

  let create = Hash_gen.create
  let clear = Hash_gen.clear
  let reset = Hash_gen.reset
  let iter = Hash_gen.iter
  let to_iter = Hash_gen.to_iter
  let iter2 = Hash_gen.iter2
  let to_list_with = Hash_gen.to_list_with
  let to_list = Hash_gen.to_list
  let to_array = Hash_gen.to_array
  let to_array_map = Hash_gen.to_array_map
  let to_array_filter_map = Hash_gen.to_array_filter_map
  let fold = Hash_gen.fold
  let length = Hash_gen.length

  let add (h : _ t) key data =
    let i = key_index h key in
    let h_data = h.data in
    h_data.!(i) <- Cons { key; data; next = h_data.!(i) };
    h.size <- h.size + 1;
    if h.size > Array.length h_data lsl 1 then Hash_gen.resize key_index h

  let add_or_update (h : 'a t) (key : key) ~update:(modf : 'a -> 'a)
      (default : 'a) =
    (let rec find_bucket (bucketlist : _ bucket) =
       (match bucketlist with
        | Cons rhs ->
            if equal_key rhs.key key then (
              let data = modf rhs.data in
              rhs.data <- data;
              Some data)
            else find_bucket rhs.next
        | Empty -> None
         : 'a option)
     in
     let i = key_index h key in
     let h_data = h.data in
     match find_bucket h_data.!(i) with
     | Some data -> data
     | None ->
         h_data.!(i) <- Cons { key; data = default; next = h_data.!(i) };
         h.size <- h.size + 1;
         if h.size > Array.length h_data lsl 1 then Hash_gen.resize key_index h;
         default
      : 'a)

  let remove (h : _ t) key =
    let i = key_index h key in
    let h_data = h.data in
    Hash_gen.remove_bucket h i key ~prec:Empty h_data.!(i) equal_key

  let rec find_rec key (bucketlist : _ bucket) =
    match bucketlist with
    | Empty -> raise (Key_not_found key)
    | Cons rhs ->
        if equal_key key rhs.key then rhs.data else find_rec key rhs.next

  let find_exn (h : _ t) key =
    match h.data.!(key_index h key) with
    | Empty -> raise (Key_not_found key)
    | Cons rhs -> (
        if equal_key key rhs.key then rhs.data
        else
          match rhs.next with
          | Empty -> raise (Key_not_found key)
          | Cons rhs -> (
              if equal_key key rhs.key then rhs.data
              else
                match rhs.next with
                | Empty -> raise (Key_not_found key)
                | Cons rhs ->
                    if equal_key key rhs.key then rhs.data
                    else find_rec key rhs.next))

  let find_opt (h : _ t) key =
    Hash_gen.small_bucket_opt equal_key key h.data.!(key_index h key)

  let find_key_opt (h : _ t) key =
    Hash_gen.small_bucket_key_opt equal_key key h.data.!(key_index h key)

  let find_default (h : _ t) key default =
    Hash_gen.small_bucket_default equal_key key default
      h.data.!(key_index h key)

  let find_or_update (type v) (h : v t) (key : key) ~(update : key -> v) =
    (let rec find_bucket h_data i (bucketlist : _ bucket) =
       match bucketlist with
       | Cons rhs ->
           if equal_key rhs.key key then rhs.data
           else find_bucket h_data i rhs.next
       | Empty ->
           let data = update key in
           h_data.!(i) <- Hash_gen.Cons { key; data; next = h_data.!(i) };
           h.size <- h.size + 1;
           if h.size > Array.length h_data lsl 1 then
             Hash_gen.resize key_index h;
           data
     in
     let i = key_index h key in
     let h_data = h.data in
     find_bucket h_data i h_data.!(i)
      : v)

  let find_all (h : _ t) key =
    let rec find_in_bucket (bucketlist : _ bucket) =
      match bucketlist with
      | Empty -> []
      | Cons rhs ->
          if equal_key key rhs.key then rhs.data :: find_in_bucket rhs.next
          else find_in_bucket rhs.next
        [@@tail_mod_cons]
    in
    find_in_bucket h.data.!(key_index h key)

  let replace h key data =
    let i = key_index h key in
    let h_data = h.data in
    let l = h_data.!(i) in
    if Hash_gen.replace_bucket key data l equal_key then (
      h_data.!(i) <- Cons { key; data; next = l };
      h.size <- h.size + 1;
      if h.size > Array.length h_data lsl 1 then Hash_gen.resize key_index h)

  let update_if_exists h key f =
    let i = key_index h key in
    let h_data = h.data in
    let rec mutate_bucket h_data (bucketlist : _ bucket) =
      match bucketlist with
      | Cons rhs ->
          if equal_key rhs.key key then rhs.data <- f rhs.data
          else mutate_bucket h_data rhs.next
      | Empty -> ()
    in
    mutate_bucket h_data h_data.!(i)

  let mem (h : _ t) key =
    Hash_gen.small_bucket_mem h.data.!(key_index h key) equal_key key

  let of_list2 ks vs =
    let len = List.length ks in
    let map = create len in
    List.iter2 (fun k -> fun v -> add map k v) ks vs;
    map

  let of_list_map kvs f =
    let len = List.length kvs in
    let map = create len in
    Lst.iter kvs ~f:(fun kv ->
        let k, v = f kv in
        add map k v);
    map

  let of_list kvs =
    let len = List.length kvs in
    let map = create len in
    Lst.iter kvs ~f:(fun (k, v) -> add map k v);
    map

  let sexp_of_t (type a) (cb : a -> _) (x : a t) =
    Moon_sexp_conv.sexp_of_list
      (fun (k, v) -> S.List [ sexp_of_key k; cb v ])
      (to_list x)
end

module Hashset = struct
  type key = t

  include struct
    let _ = fun (_ : key) -> ()
    let equal_key = (equal : key -> key -> bool)
    let _ = equal_key
  end

  let key_index (h : _ Hashset_gen.t) (key : key) =
    hash key land (Array.length h.data - 1)

  type t = key Hashset_gen.t

  module Unsafe_external = Basic_unsafe_external
  open Unsafe_external

  let create = Hashset_gen.create
  let clear = Hashset_gen.clear
  let reset = Hashset_gen.reset
  let iter = Hashset_gen.iter
  let to_iter = Hashset_gen.to_iter
  let fold = Hashset_gen.fold
  let length = Hashset_gen.length
  let to_list = Hashset_gen.to_list

  let remove (h : _ Hashset_gen.t) key =
    let i = key_index h key in
    let h_data = h.data in
    Hashset_gen.remove_bucket h i key ~prec:Empty h_data.!(i) equal_key

  let add (h : _ Hashset_gen.t) key =
    let i = key_index h key in
    let h_data = h.data in
    let old_bucket = h_data.!(i) in
    if not (Hashset_gen.small_bucket_mem equal_key key old_bucket) then (
      h_data.!(i) <- Cons { key; next = old_bucket };
      h.size <- h.size + 1;
      if h.size > Array.length h_data lsl 1 then Hashset_gen.resize key_index h)

  let of_array arr =
    let len = Array.length arr in
    let tbl = create len in
    for i = 0 to len - 1 do
      add tbl arr.!(i)
    done;
    tbl

  let check_add (h : _ Hashset_gen.t) key =
    (let i = key_index h key in
     let h_data = h.data in
     let old_bucket = h_data.!(i) in
     if not (Hashset_gen.small_bucket_mem equal_key key old_bucket) then (
       h_data.!(i) <- Cons { key; next = old_bucket };
       h.size <- h.size + 1;
       if h.size > Array.length h_data lsl 1 then Hashset_gen.resize key_index h;
       true)
     else false
      : bool)

  let find_or_add (h : _ Hashset_gen.t) key =
    (let i = key_index h key in
     let h_data = h.data in
     let old_bucket = h_data.!(i) in
     match Hashset_gen.small_bucket_find equal_key key old_bucket with
     | Some key0 -> key0
     | None ->
         h_data.!(i) <- Cons { key; next = old_bucket };
         h.size <- h.size + 1;
         if h.size > Array.length h_data lsl 1 then
           Hashset_gen.resize key_index h;
         key
      : key)

  let mem (h : _ Hashset_gen.t) key =
    Hashset_gen.small_bucket_mem equal_key key h.data.!(key_index h key)
end

module Ordered_hash = struct
  type key = t

  include struct
    let _ = fun (_ : key) -> ()
    let equal_key = (equal : key -> key -> bool)
    let _ = equal_key
  end

  type 'value t = (key, 'value) Ordered_hash_map_gen.t

  let key_index (h : _ t) (key : key) = hash key land (Array.length h.data - 1)

  module Unsafe_external = Basic_unsafe_external
  open Unsafe_external

  let choose = Ordered_hash_map_gen.choose
  and clear = Ordered_hash_map_gen.clear
  and create = Ordered_hash_map_gen.create
  and elements = Ordered_hash_map_gen.elements
  and fold = Ordered_hash_map_gen.fold
  and iter = Ordered_hash_map_gen.iter
  and length = Ordered_hash_map_gen.length
  and reset = Ordered_hash_map_gen.reset
  and resize = Ordered_hash_map_gen.resize
  and to_sorted_array = Ordered_hash_map_gen.to_sorted_array

  type ('a, 'b) bucket = ('a, 'b) Ordered_hash_map_gen.bucket

  let rec small_bucket_mem key (lst : (key, _) bucket) =
    match lst with
    | Empty -> false
    | Cons rhs -> (
        equal_key key rhs.key
        ||
        match rhs.next with
        | Empty -> false
        | Cons rhs -> (
            equal_key key rhs.key
            ||
            match rhs.next with
            | Empty -> false
            | Cons rhs -> equal_key key rhs.key || small_bucket_mem key rhs.next
            ))

  let rec small_bucket_rank key (lst : (key, _) bucket) =
    match lst with
    | Empty -> -1
    | Cons rhs -> (
        if equal_key key rhs.key then rhs.ord
        else
          match rhs.next with
          | Empty -> -1
          | Cons rhs -> (
              if equal_key key rhs.key then rhs.ord
              else
                match rhs.next with
                | Empty -> -1
                | Cons rhs ->
                    if equal_key key rhs.key then rhs.ord
                    else small_bucket_rank key rhs.next))

  let rec small_bucket_find_value key (lst : (_, _) bucket) =
    match lst with
    | Empty -> raise Not_found
    | Cons rhs -> (
        if equal_key key rhs.key then rhs.data
        else
          match rhs.next with
          | Empty -> raise Not_found
          | Cons rhs -> (
              if equal_key key rhs.key then rhs.data
              else
                match rhs.next with
                | Empty -> raise Not_found
                | Cons rhs ->
                    if equal_key key rhs.key then rhs.data
                    else small_bucket_find_value key rhs.next))

  let add h key value =
    let i = key_index h key in
    if not (small_bucket_mem key h.data.(i)) then (
      h.data.(i) <- Cons { key; ord = h.size; data = value; next = h.data.(i) };
      h.size <- h.size + 1;
      if h.size > Array.length h.data lsl 1 then resize key_index h)

  let mem (h : _ t) key = small_bucket_mem key h.data.!(key_index h key)
  let rank (h : _ t) key = small_bucket_rank key h.data.!(key_index h key)

  let find_value (h : _ t) key =
    small_bucket_find_value key h.data.!(key_index h key)
end
