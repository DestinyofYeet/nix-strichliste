<?php

namespace App\Serializer;

use App\Entity\User;
use App\Service\UserService;

class UserSerializer {

    /**
     * @var UserService
     */
    private $userService;

    function __construct(UserService $userService) {
        $this->userService = $userService;
    }

    function serialize(User $user): array {
        return [
            'id' => $user->getId(),
            'name' => $user->getName(),
            'email' => $user->getEmail(),
            'balance' => $user->getBalance(),
            'isActive' => $this->userService->isActive($user),
            'isDisabled' => $user->isDisabled(),
            'created' => $user->getCreated()->format('Y-m-d H:i:s'),
            'updated' => $user->getUpdated() ? $user->getUpdated()->format('Y-m-d H:i:s') : null
        ];
    }
}