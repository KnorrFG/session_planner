import nigui


proc createNamedTextArea*(name: string): (LayoutContainer, TextArea)=
  let layout = newLayoutContainer(Layout_Vertical)
  layout.frame = newFrame(name)
  let textArea = newTextArea()
  layout.add(textArea)
  (layout, textArea)
    
