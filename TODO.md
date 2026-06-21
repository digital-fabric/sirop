- Implement and test `(@counter += 1)`: InstanceVariableOrWriteNode
- Update Prism to ~>1.9.0
- Solve deprecation warning:

```
/home/sharon/.local/share/rv/rubies/ruby-4.0.3/lib/ruby/gems/4.0.0/gems/prism-1.9.0/lib/prism/node_ext.rb:430: warning: [deprecation]: Prism::IndexOperatorWriteNode#Prism::IndexOperatorWriteNode#operator_loc is deprecated and will be removed in the next major version. Use Prism::IndexOperatorWriteNode#binary_operator_loc instead.
/home/sharon/.local/share/rv/rubies/ruby-4.0.3/lib/ruby/gems/4.0.0/gems/prism-1.9.0/lib/prism/node_ext.rb:430:in 'Prism::IndexOperatorWriteNode#operator_loc'
/home/sharon/.local/share/rv/rubies/ruby-4.0.3/lib/ruby/gems/4.0.0/gems/sirop-1.0.3/lib/sirop/sourcifier.rb:539:in 'Sirop::Sourcifier#visit_index_operator_write_node'
/home/sharon/.local/share/rv/rubies/ruby-4.0.3/lib/ruby/gems/4.0.0/gems/prism-1.9.0/lib/prism/node.rb:9921:in 'Prism::IndexOperatorWriteNode#accept'
```
