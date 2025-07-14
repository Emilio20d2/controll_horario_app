# app/validators/multiple_of_validator.rb
#
# Validador personalizado para asegurar que un valor numérico
# es un múltiplo de un número específico (ej. 0.25).
class MultipleOfValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # No hacemos nada si el valor es nulo; otras validaciones (como 'presence') se encargarán de eso.
    return if value.nil?

    multiple = options.fetch(:multiple_of)

    # Para evitar problemas de precisión con números flotantes, multiplicamos por 100
    # y usamos el operador de módulo (%) con enteros.
    unless (value.to_d * 100).to_i % (multiple * 100).to_i == 0
      record.errors.add(attribute, (options[:message] || "debe ser un múltiplo de #{multiple}"))
    end
  end
end