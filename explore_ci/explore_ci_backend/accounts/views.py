from rest_framework import generics, permissions

from .serializers import RegisterSerializer, UserSerializer


class RegisterView(generics.CreateAPIView):
    """Inscription par email / mot de passe."""

    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]


class MeView(generics.RetrieveAPIView):
    """Retourne l'utilisateur actuellement authentifié."""

    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user
