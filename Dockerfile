FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY . .
RUN dotnet restore

# Copy everything else and build
COPY /src/. ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
ENV TZ="America/Santo_Domingo"
ARG ASPNETCORE_ENVIRONMENT
ARG CONNECTION_STRING
ARG HOST_AUTHENTICATION_API
WORKDIR /app
COPY --from=build-env /app/out .
ENTRYPOINT ["dotnet", "GestionAutorizaciones.API.dll"]
