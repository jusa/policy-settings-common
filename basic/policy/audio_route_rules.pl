/*
 *
 */
resource_class_privacy(proclaimer , public).
resource_class_privacy(navigator  , public).
resource_class_privacy(call       , public).
resource_class_privacy(videoeditor, public).
resource_class_privacy(camera     , public).
resource_class_privacy(ringtone   , public).
resource_class_privacy(alarm      , public).
resource_class_privacy(game       , public).
resource_class_privacy(player     , public).
resource_class_privacy(implicit   , public).
resource_class_privacy(event      , public).
resource_class_privacy(background , public).
resource_class_privacy(alien      , public).
resource_class_privacy(nobody     , public).

/*
 * implicated privacies
 */
%
% active video calls implicate 'public' privacy
%
implicated_privacy(public) :-
    resource:resource_owner(audio_playback, call),
    resource:resource_owner(video_playback, call).


/*
 * Here is a bunch of exception for audio routing
 */
%
% never route voice call output to public devices
% explicitly demands it via privacy override
%
invalid_audio_device_choice(call, sink, Device) :-
    ((audio_route:privacy_override(public) ; implicated_privacy(public)) *-> Privacy=private ; Privacy=public),
    audio_device_privacy(Privacy, Device).

% do not route *forcall if call is not active
%
invalid_audio_device_choice(Class, sink, ihfforcall) :-
    not(Class = call).

invalid_audio_device_choice(Class, _, headsetforcall) :-
    not(Class = call).

invalid_audio_device_choice(Class, sink, headphoneforcall) :-
    not(Class = call).

invalid_audio_device_choice(Class, sink, bthspforcall) :-
    not(Class = call).

invalid_audio_device_choice(Class, source, bthspforcall) :-
    not(Class = call).

%
% Do not route to bthspforcall if bluetooth_override is active, that is, anything but default.
%
invalid_audio_device_choice(call, _, bthspforcall) :-
    audio_route:bluetooth_override(A),
    not(A = default).

% do not route bta2dp when call is incoming or outgoing
%invalid_audio_device_choice(call, sink, bta2dp) :-
%    telephony:has_alerting_call,!;      % # incoming created call
%    telephony:has_outgoing_call,!.      % # outgoing created call


%
% if a call were active during navigation the call should determine the route
%
invalid_audio_device_choice(navigator, sink, Device) :-
    resource:granted_resource(call, audio_playback),
    invalid_audio_device_choice(call, sink, Device).

%
% do not route video call to earpiece
%
invalid_audio_device_choice(call, sink, earpiece) :-
    resource:resource_owner(video_playback, call).

invalid_audio_device_choice(call, sink, earpieceandtvout) :-
    resource:resource_owner(video_playback, call).


%
% Do not route ringtones to private accessories except in silent mode to 
% headphone or headset
%
invalid_audio_device_choice(ringtone, sink, Device) :-
    is_silent_profile *->(not(Device = headphone), not(Device = headset));
    audio_accessory(Device),
    audio_device_privacy(private, Device),
    audio_device_type(sink, Device).


%
% do not route anything to earpiece if we had no active call 
%
invalid_audio_device_choice(_, sink, earpiece) :-
    not(resource:granted_resource(call, audio_playback)).

invalid_audio_device_choice(_, sink, earpieceandtvout) :-
    not(resource:granted_resource(call, audio_playback)).


%
% route only ringtone to twin device like ihfandheadset
%
invalid_audio_device_choice(Class, sink, TwinDevice) :-
    twin_audio_device(TwinDevice),
    not(notification_class(Class)).

% do not route ringtone to twindevice in silent mode
invalid_audio_device_choice(ringtone, sink, Device) :- 
    is_silent_profile,
    twin_audio_device(Device).

%
% do not route cscall or ipcall to bta2dp
%
invalid_audio_device_choice(call, _, bta2dp).
invalid_audio_device_choice(call, _, tvoutandbta2dp).
%
% do not route calls to regular bthsp
%
invalid_audio_device_choice(call, _, bthsp).
invalid_audio_device_choice(call, _, tvoutandbthsp).

%
% never route anyting to headmike
%
invalid_audio_device_choice(_, source, headmike).

%
% route the source to accessories that have mike as well if the
% sink is also routed there
% 
invalid_audio_device_choice(_, source, bthsp) :-
    not(audio_route:get_route(sink, bthsp)).
invalid_audio_device_choice(_, source, tvoutandbthsp) :-
    not(audio_route:get_route(sink, tvoutandbthsp)).

invalid_audio_device_choice(_, source, headset) :-
    not(audio_route:get_route(sink, headset)).

%
% do not route microphone to camera if video and audio recording are on.
% backmicrophone will be used instead.
invalid_audio_device_choice(camera, source, microphone) :-
    resource:granted_resource(camera, audio_recording),
    resource:granted_resource(camera, video_recording).

invalid_audio_device_choice(_, _, incompatible).


/*
 * Supporting predicates
 */
% true when active profile is 'silent'
is_silent_profile :-
    fact_exists('com.nokia.policy.current_profile', [value], [silent]).

% true when touchscreen.sound.level is 0
is_silent_feedback :-
    fact_exists('com.nokia.policy.current_profile', ['touchscreen.sound.level'], ['0']).
