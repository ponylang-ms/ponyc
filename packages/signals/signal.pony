use @asio_event_create[AsioEventID](owner: AsioEventNotify, fd: U32,
  flags: U32, nsec: U64, noisy: Bool)
use @asio_event_unsubscribe[None](event: AsioEventID)
use @asio_event_destroy[None](event: AsioEventID)

primitive Sig
  """
  Define the portable signal numbers. Other signals can be used, but they are
  not guaranteed to be portable.
  """
  fun hup(): U32 => 1
  fun int(): U32 => 2
  fun quit(): U32 => 3
  fun abort(): U32 => 6
  fun kill(): U32 => 9
  fun alarm(): U32 => 14
  fun term(): U32 => 15

actor SignalHandler
  """
  Listen for a specific signal.
  """
  let _notify: SignalNotify
  let _sig: U32
  var _event: AsioEventID

  new create(notify: SignalNotify iso, sig: U32) =>
    """
    Create a signal handler.
    """
    _notify = consume notify
    _sig = sig
    _event = @asio_event_create(this, 0, AsioEvent.signal(), sig.u64(), false)

  be raise() =>
    """
    Raise the signal.
    """
    SignalRaise(_sig)

  be dispose() =>
    """
    Dispose of the signal handler.
    """
    _dispose()

  be _event_notify(event: AsioEventID, flags: U32, arg: U32) =>
    """
    Called when the signal is received, or when the AsioEventID can be
    destroyed.
    """
    if AsioEvent.disposable(flags) then
      @asio_event_destroy(event)
    elseif event is _event then
      if not _notify(arg) then
        _dispose()
      end
    end

  fun ref _dispose() =>
    """
    Dispose of the AsioEventID.
    """
    if not _event.is_null() then
      @asio_event_unsubscribe(_event)
      _event = AsioEvent.none()
      _notify.dispose()
    end