
# destructure only what's needed
{a,input,form,ol,li,div,button,h1,h2,small,label} = DOM

require! {
  co
  uuid
  \./Input
  \./Check
  \./Footer
}

# TodoPage
module.exports = component page-mixins, ({props}) ->

  # TodoList
  todo-list = component ({props, on-delete, on-change, show-name}) ->
    visible = (props.get \visible) or \all
    cn      = -> cx {active:visible is it}
    show    = (active) -> props.update \visible -> active

    # FIXME hack until "for x from y!" es6 iterators
    # https://github.com/gkz/LiveScript/issues/667
    list = (Object.keys props.toJS!).filter (k) ->
      c  = props.get-in [k, \completed]
      switch visible
        | \all       => true
        | \active    => !c
        | \completed => c

    ol void [
      # todo list
      for let k in list
        li void [
          Check {props:(props.cursor [k, \completed]), on-change}
          Input {props:(props.cursor [k, \title])}
          if show-name then div {class-name:\name} (props.get-in [k, \name])
          div {
            title: \Delete
            class-name: \delete,
            on-click: ->
              if confirm 'Permanently delete?'
                props.delete k
                if on-delete then on-delete!
          }, \x
        ]
      # filters
      div {class-name:\actions} [
        a {on-click:(-> show \all), class-name:(cn \all)} \All
        a {on-click:(-> show \active), class-name:(cn \active)} \Active
        a {on-click:(-> show \completed), class-name:(cn \completed)} \Completed
      ]
    ]

  paths = {
    title: [\locals, \current-title]
    is-public: [\session, \is-public]
    public-todo:  [\public, \todos]
    session-todo: [\session, \todos]
  }
  name = props.get-in [\session, \name]
  is-public = props.cursor paths.is-public

  div class-name: \TodoPage, [
    h1 void "#{if name then name else 'My TODO'}"
    form {on-submit:-> it.prevent-default!} [
      Input {ref:\focus, props:(props.cursor paths.title), placeholder:'Add an Item ...', class-name:\indent}
      small void [ Check {props:is-public, label:'Public', title:'Seen by Everyone'} ]
      button {on-click:-> # save session or public
        if title = props.get-in paths.title
          path = if is-public.deref! then paths.public-todo else paths.session-todo
          date = new Date!get-time!
          todo = {title, -completed, name, date}
          props
            ..cursor path .set uuid.v4!, Immutable.fromJS todo              # add
            ..set-in paths.title, ''                                        # reset ui
          if path is paths.public-todo then sync-public! else sync-session! # save
      }, \Save
    ]

    # render my session todos
    todo-list {props:(props.cursor paths.session-todo), on-delete:(-> sync-session!), on-change:(-> sync-session!)}

    # render public todos
    h2 void \Public
    todo-list {props:(props.cursor paths.public-todo), +show-name, on-delete:(-> sync-public!), on-change:(-> sync-public!)}

    Footer {props}
  ]

