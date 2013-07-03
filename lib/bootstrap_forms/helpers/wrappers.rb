module BootstrapForms
  module Helpers
    module Wrappers
      def control_group_div(control_group_options = {}, &block)
        field_errors = error_string
        if @field_options[:error]
          (@field_options[:error] << ", " << field_errors) if field_errors
        else
          @field_options[:error] = field_errors
        end

        klasses = []
        klasses << 'control-group' unless @field_options[:control_group] == false
        klasses << 'error' if @field_options[:error]
        klasses << 'success' if @field_options[:success]
        klasses << 'warning' if @field_options[:warning]
        klasses << 'required' if @field_options.merge(required_attribute)[:required]

        control_group_options[:class] = klasses if !klasses.empty?

        if @field_options[:control_group] == false
          yield
        else
          content_tag(:div, control_group_options, &block)
        end
      end

      def error_string(options = {})
        if respond_to?(:object) and object.respond_to?(:errors)
          errors = object.errors[@name]
          if errors.present?
            errors.map { |e|
              object.errors.full_message(@name, e)
            }.join(", ")
          end
        end
      end

      def human_attribute_name
        object.class.human_attribute_name(@name) rescue @name.titleize
      end

      def input_div(content_options = {}, &block)
        content_options[:class] = 'controls'
        if @field_options[:control_group] == false
          @field_options.delete :control_group
          write_input_div(&block)
        else
          content_tag(:div, :class => 'controls') do
            write_input_div(&block)
          end
        end
      end

      def write_input_div(options = {}, &block)
        if @field_options[:append] || @field_options[:prepend] || @field_options[:append_button]
          options[:class] ||= [options[:class]].flatten.compact
          options[:class] << 'input-prepend' if @field_options[:prepend]
          options[:class] << 'input-append' if @field_options[:append] || @field_options[:append_button]
          html = content_tag(:div, options, &block)
          html << extras(false, &block) if @field_options[:help_inline] || @field_options[:help_block] || @field_options[:error] || @field_options[:success] || @field_options[:warning]
          html
        else
          yield if block_given?
        end
      end

      def label_field(label_options = {}, &block)
        if @field_options[:label] == '' || @field_options[:label] == false
          return ''.html_safe
        else
          label_options[:class] = 'control-label' unless @field_options[:control_group] == false
          if respond_to?(:object)
             label(@name, block_given? ? block : @field_options[:label], label_options)
           else
             label_tag(@name, block_given? ? block : @field_options[:label], label_options)
           end
        end
      end

      def required_attribute
        return {} if @field_options.present? && @field_options.has_key?(:required) && !@field_options[:required]

        if respond_to?(:object) and object.respond_to?(:errors) and object.class.respond_to?('validators_on')
          return { :required => true } if object.class.validators_on(@name).any? { |v| v.kind_of?( ActiveModel::Validations::PresenceValidator ) && valid_validator?( v ) }
        end
        {}
      end

      def valid_validator?(validator)
        !conditional_validators?(validator) && action_validator_match?(validator)
      end

      def conditional_validators?(validator)
        validator.options.include?(:if) || validator.options.include?(:unless)
      end

      def action_validator_match?(validator)
        return true if !validator.options.include?(:on)
        case validator.options[:on]
        when :save
          true
        when :create
          !object.persisted?
        when :update
          object.persisted?
        end
      end


      %w(help_inline error success warning help_block append append_button prepend).each do |method_name|
        define_method(method_name) do |*args|
          return '' unless value = @field_options[method_name.to_sym]

          escape = true
          tag_options = args.first || {}
          case method_name
          when 'help_block'
            element = :span
            tag_options[:class] = 'help-block'
          when 'append', 'prepend'
            element = :span
            tag_options[:class] = 'add-on'
          when 'append_button'
            element = :button
            button_options = value
            value = ''

            if button_options.has_key? :icon
              value << content_tag(:i, '', { :class => button_options.delete(:icon) })
              value << ' '
              escape = false
            end

            value << button_options.delete(:label)

            tag_options[:type] = 'button'
            tag_options[:class] = 'btn'
            tag_options.merge! button_options
          else
            element = :span
            tag_options[:class] = 'help-inline'
          end
          content_tag(element, value, tag_options, escape)
        end
      end

      def extras(input_append = nil, &block)
        case input_append
        when nil
          [prepend, (yield if block_given?), append, append_button, help_inline, error, success, warning, help_block].join('').html_safe
        when true
          [prepend, (yield if block_given?), append, append_button].join('').html_safe
        when false
          [help_inline, error, success, warning, help_block].join('').html_safe
        end
      end

      def objectify_options(options)
        super.except(:label, :help_inline, :error, :success, :warning, :help_block, :prepend, :append, :append_button, :control_group)
      end
    end
  end
end
