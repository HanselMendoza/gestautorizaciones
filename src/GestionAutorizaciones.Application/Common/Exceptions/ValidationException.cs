using FluentValidation.Results;
using System;
using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Exceptions
{
    public class ValidationException : Exception
    {
        public ValidationException(string message) : base(message) {}
        public ValidationException(IEnumerable<ValidationFailure> failures) : this(GetFailuresInPlainText(failures)) {}

        public override string StackTrace => $"{nameof(ValidationException)}: {this.Message}";
        private static string GetFailuresInPlainText(IEnumerable<ValidationFailure> failures) => string.Join(", ", failures);
    }
}