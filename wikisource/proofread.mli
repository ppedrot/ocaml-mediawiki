open Datatypes

type proofread_page = {
  pr_head : string;
  pr_text : string;
  pr_foot : string;
  pr_level : int;
  pr_user : user;
}
