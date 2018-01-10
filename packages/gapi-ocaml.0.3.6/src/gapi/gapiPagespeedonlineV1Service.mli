(* Warning! This file is generated. Modify at your own risk. *)

(** Service definition for PageSpeed Insights API (v1).
  
  Lets you analyze the performance of a web page and get tailored suggestions to make that page faster..
  
  For more information about this service, see the
  {{:https://developers.google.com/speed/docs/insights/v1/getting_started}API Documentation}.
  *)

module PagespeedapiResource :
sig
  
  module Strategy :
  sig
    type t =
      | Default
      | Desktop (** Fetch and analyze the URL for desktop browsers *)
      | Mobile (** Fetch and analyze the URL for mobile devices *)
      
    val to_string : t -> string
    
    val of_string : string -> t
    
  end
  
  (** Runs PageSpeed analysis on the page at the specified URL, and returns a PageSpeed score, a list of suggestions to make that page faster, and other information.
    
    @param base_url Service endpoint base URL (defaults to ["https://www.googleapis.com/pagespeedonline/v1/"]).
    @param std_params Optional standard parameters.
    @param filter_third_party_resources Indicates if third party resources should be filtered out before PageSpeed analysis.
    @param screenshot Indicates if binary data containing a screenshot should be included
    @param locale The locale used to localize formatted results
    @param rule A PageSpeed rule to run; if none are given, all rules are run
    @param strategy The analysis strategy to use
    @param url The URL to fetch and analyze
    *)
  val runpagespeed :
    ?base_url:string ->
    ?std_params:GapiService.StandardParameters.t ->
    ?filter_third_party_resources:bool ->
    ?screenshot:bool ->
    ?locale:string ->
    ?rule:string list ->
    ?strategy:Strategy.t ->
    url:string ->
    GapiConversation.Session.t ->
    GapiPagespeedonlineV1Model.Result.t * GapiConversation.Session.t
  
  
end


