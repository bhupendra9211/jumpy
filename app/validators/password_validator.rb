class PasswordValidator < ActiveModel::EachValidator
  PASSWORD_FORMAT = /\A
    (?=.{8,})          # Must contain 8 or more characters
    (?=.*\d)           # Must contain a digit
    (?=.*[a-z])        # Must contain a lower case character
    (?=.*[A-Z])        # Must contain an upper case character
    (?=.*[[:^alnum:]]) # Must contain a symbol
    /x
  def validate_each(record, attribute, value)
    return if PASSWORD_FORMAT.match?(value)

    record.errors.add attribute, (options[:message] || :must_be_valid_with_)
  end
end
