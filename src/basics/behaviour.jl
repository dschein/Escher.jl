import Base: >>>

export hasstate,
       keypress,
       Key,
       nokey,
       clickable,
       selectable,
       draggable,
       resizable,
       leftbutton,
       rightbutton,
       scrollbutton


@api hasstate => WithState <: Behaviour begin
    curry(tile::Tile)
    kwarg(name::Symbol=:_state)
    kwarg(attr::String="value")
    kwarg(elem::String="::parent")
    kwarg(trigger::String="change")
    kwarg(source::String="")
end

render(t::WithState) =
    render(t.tile) <<
        Elem("watch-state", name=t.name,
             attr=t.attr, trigger=t.trigger,
             elem=t.elem, source=t.source)

# Sample a bunch of signals upon changes to another bunch of signals
# Returns a signal of dict of signal values
@api samplesignals => SignalSampler <: Behaviour begin
    arg(signals::AbstractArray)
    arg(triggers::AbstractArray)
    curry(tile::Tile)
    typedkwarg(name::Symbol=:_sampler)
end

samplesignals(tosample::Symbol, triggers::Symbol, x...; name=:_sampler) =
    samplesignals([tosample], [triggers], x...; name=name)
samplesignals(tosample::Symbol, triggers, x...; name=:_sampler) =
    samplesignals([tosample], [triggers], x...; name=name)
samplesignals(tosample, triggers::Symbol, x...; name=:_sampler) =
    samplesignals(tosample, [triggers], x...; name=name)

render(sig::SignalSampler) =
    render(sig.tile) <<
        Elem("signal-sampler",
            name=sig.name,
            signals=sig.signals,
            triggers=sig.triggers)


@api keypress => Keypress <: Behaviour begin
    arg(keys::String)
    curry(tile::Tile)
    kwarg(name::Symbol=:_keys)
    kwarg(onpress::String="")
end

render(k::Keypress) =
    (render(k.tile) & [:attributes => [:tabindex => 1]]) <<
        (Elem("keypress-behaviour", keys=k.keys, name=k.name) &
            (k.onpress != "" ? [:onpress=>k.onpress] : Dict()))

immutable Key
    key::String
    alt::Bool
    ctrl::Bool
    meta::Bool
    shift::Bool
end

const nokey = Key("", false, false, false, false)

decodeJSON(sig::Input{Key}, d::Dict) =
    Key(d["key"], d["alt"], d["ctrl"], d["meta"], d["shift"])

abstract MouseButton

@terms MouseButton begin
    leftbutton => LeftButton
    rightbutton => RightButton
    scrollbutton => ScrollButton
end

@api clickable => Clickable <: Behaviour begin
    typedarg(buttons::AbstractArray=[leftbutton])
    curry(tile::Tile)
    kwarg(name::Symbol=:_clicks)
end

button_number(::LeftButton) = 1
button_number(::RightButton) = 2
button_number(::ScrollButton) = 3

render(c::Clickable) =
    render(c.tile) << Elem("clickable-behaviour", name=c.name,
                        buttons=string(map(button_number, c.buttons)))


@api selectable => Selectable <: Behaviour begin
    curry(tile::Tile)
    kwarg(name::Symbol=:_clicks)
    kwarg(elem::String="::parent")
end

render(t::Selectable) =
    render(t.tile) <<
        Elem("selectable-behaviour", name=t.name, elem=t.elem)


convert(::Type{MouseButton}, x::Int) =
    try [leftbutton, rightbutton, scrollbutton][x]
    catch error("Invalid mouse button code: $x")
    end

abstract MouseState

@terms MouseState begin
    mousedown => MouseDown
    mouseup => MouseUp
end

@api hoverable => Hoverable <: Behaviour begin
    typedarg(get_coords::Bool=false)
    curry(tile::Tile)
    kwarg(name::Symbol=:_hover)
end

immutable Hover
    state::MouseState
    position::(Float64, Float64)
end

immutable Editable <: Behaviour
    name::Symbol
    tile::Tile
end

## UI-side global channels
import Base: send, recv
export send, recv, wire

immutable ChanSend <: Tile
    chan::Symbol
    watch::Symbol
    tile::Tile
end
send(chan::Symbol, b::Behaviour) =
    ChanSend(chan, b.name, b)

render(chan::ChanSend) =
    render(chan.tile) <<
        Elem("chan-send",
            chan=chan.chan, watch=chan.watch)


immutable ChanRecv <: Tile
    chan::Symbol
    attr::Symbol
    tile::Tile
end
recv(chan::Symbol, t, attr) =
    ChanRecv(chan, attr, t)

render(chan::ChanRecv) =
    render(chan.tile) <<
        Elem("chan-recv",
            chan=chan.chan, attr=chan.attr)


wire(a::Behaviour, b, chan, attribute) =
    send(chan, a), recv(chan, b, attribute)
