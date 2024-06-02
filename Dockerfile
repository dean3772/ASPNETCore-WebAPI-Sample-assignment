# Use the official .NET Core SDK as a parent image
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /app

# Copy the project file and restore any dependencies
COPY SampleWebApiAspNetCore/SampleWebApiAspNetCore.csproj SampleWebApiAspNetCore/
RUN dotnet restore SampleWebApiAspNetCore/SampleWebApiAspNetCore.csproj

# Copy the rest of the application code
COPY SampleWebApiAspNetCore/. SampleWebApiAspNetCore/

# Publish the application
WORKDIR /app/SampleWebApiAspNetCore
RUN dotnet publish -c Release -o out

# Build the runtime image
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS runtime
WORKDIR /app
COPY --from=build /app/SampleWebApiAspNetCore/out ./

# Expose the port your application will run on
EXPOSE 7124

# Start the application
ENTRYPOINT ["dotnet", "SampleWebApiAspNetCore.dll"]

ENV ASPNETCORE_URLS http://*:80
ENV ASPNETCORE_ENVIRONMENT=Development
