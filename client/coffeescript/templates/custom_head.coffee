_.extend( Template.custom_head,
  domain: -> 
    Instances.findOne().domain #fix this
)
